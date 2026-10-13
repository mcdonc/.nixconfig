# SSO gate for nginx pages via oauth2-proxy + Pocket ID (auth_request).
#
#   https://<host>.tail33f8f4.ts.net/          -> Pocket ID (public, unchanged)
#   https://<host>.tail33f8f4.ts.net/oauth2/*  -> oauth2-proxy endpoints
#                                                  (login/callback, hosted on
#                                                  the pocket-id vhost)
#   https://<host>.tail33f8f4.ts.net:9443/     -> protected page(s): every
#                                                  request is challenged
#
# nginx challenges requests on the protected vhost with auth_request ->
# oauth2-proxy (127.0.0.1:4180) -> Pocket ID as OIDC provider. Browsers
# without a session are 307'd to /oauth2/start, authenticate against Pocket
# ID (passkey), and are redirected back. Cookies are shared across the two
# ports because cookies ignore ports and both vhosts use the same hostname.
#
# The OIDC client is provisioned without a browser: a oneshot unit calls
# Pocket ID's admin API (X-API-KEY, STATIC_API_KEY from roles/pocket-id.nix)
# over the loopback INTERNAL_APP_URL and keeps a client with a deterministic
# id ("oauth2-proxy") and exactly one active secret, whose value is captured
# to /var/lib/pocket-id-sso/client-secret. The cookie secret is generated
# alongside it. Both persist across rebuilds, so this role needs no new
# agenix secrets. If the secret is ever revoked in the Pocket ID UI, recover:
#
#   rm /var/lib/pocket-id-sso/client-secret
#   systemctl restart pocket-id-sso-configure.service oauth2-proxy.service
#
# Requires roles/pocket-id.nix on the same host (asserted below). Reuse for
# more protected pages: add locations/vhosts that auth_request the same
# = /oauth2/auth handler (or proxy to something real instead of the demo
# static page below).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  tailnet = "tail33f8f4.ts.net";
  fqdn = "${config.networking.hostName}.${tailnet}";
  # Same cert as the pocket-id vhost (roles/pocket-id.nix generates it
  # world-readable precisely so non-root apps can use it as a CA/trust anchor)
  certDir = "/var/lib/${config.networking.hostName}-tls";
  stateDir = "/var/lib/pocket-id-sso";
  # Deterministic so rebuilds converge instead of accumulating clients.
  # Satisfies Pocket ID's client_id pattern ^[a-z0-9][a-z0-9._-]*$.
  clientId = "oauth2-proxy";
  protectedPort = 9443;
in
{
  assertions = [
    {
      assertion = config.services.pocket-id.enable;
      message = "roles/pocket-id-sso.nix requires roles/pocket-id.nix";
    }
  ];

  # --- oauth2-proxy --------------------------------------------------------
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://${fqdn}";
    scope = "openid profile email";
    clientID = clientId;
    clientSecretFile = "${stateDir}/client-secret";
    redirectURL = "https://${fqdn}/oauth2/callback";
    httpAddress = "127.0.0.1:4180";
    email.domains = [ "*" ]; # any Pocket ID user may sign in
    cookie = {
      secure = true; # https-only
      secretFile = "${stateDir}/cookie-secret";
    };
    setXauthrequest = true; # expose X-User/X-Email to backend locations
    reverseProxy = true;
    trustedProxyIP = [ "127.0.0.1" ]; # nginx on localhost is the only client
    extraConfig = {
      # Pocket ID's front door uses the self-signed cert from <host>-tls;
      # trust exactly that cert rather than disabling verification.
      provider-ca-file = "${certDir}/${fqdn}.crt";
      # Accept rd= redirects back to any port on this host (the protected
      # vhost lives on :${toString protectedPort}).
      whitelist-domain = fqdn;
    };
  };

  # --- OIDC client provisioning (idempotent, no browser) -------------------
  systemd.services.pocket-id-sso-configure = {
    description = "Provision oauth2-proxy OIDC client in Pocket ID";
    # Loopback INTERNAL_APP_URL: no TLS trust needed for the API calls.
    after = [ "pocket-id.service" ];
    requires = [ "pocket-id.service" ];
    before = [ "oauth2-proxy.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    path = with pkgs; [
      curl
      jq
      openssl
    ];
    script = ''
      set -eu
      api=http://127.0.0.1:1411/api
      hdr="X-API-KEY: $(cat ${config.age.secrets."pocket-id-static-api-key".path})"
      body='{"id":"oauth2-proxy","name":"oauth2-proxy","description":"nginx auth_request gate","callbackURLs":["https://${fqdn}/oauth2/callback"],"isPublic":false,"pkceEnabled":false,"requiresReauthentication":false,"requiresPushedAuthorizationRequests":false,"skipConsent":true,"credentials":{"secrets":[]}}'

      # pocket-id is Type=simple (API not immediately ready): retry the probe
      code=$(curl -sS --retry 30 --retry-delay 2 --retry-connrefused --retry-all-errors \
        -H "$hdr" -o /dev/null -w '%{http_code}' "$api/oidc/clients/oauth2-proxy")
      if [ "$code" = 404 ]; then
        curl -sf -H "$hdr" -H 'Content-Type: application/json' \
          -d "$body" "$api/oidc/clients" >/dev/null
      elif [ "$code" = 200 ]; then
        # converge name/callbackURLs (secret set is managed separately below)
        curl -sf -X PUT -H "$hdr" -H 'Content-Type: application/json' \
          -d "$body" "$api/oidc/clients/oauth2-proxy" >/dev/null
      else
        echo "pocket-id API returned unexpected status $code" >&2
        exit 1
      fi

      install -d -m 0700 -o root -g root ${stateDir}

      if [ ! -s ${stateDir}/client-secret ]; then
        # Create a fresh secret and keep only that one.
        new=$(curl -sf -X POST -H "$hdr" -H 'Content-Type: application/json' \
          -d '{}' "$api/oidc/clients/oauth2-proxy/secrets")
        umask 077
        printf '%s' "$(jq -r .secret <<<"$new")" > ${stateDir}/client-secret
        keep=$(jq -r .id <<<"$new")
        for sid in $(curl -sf -H "$hdr" \
            "$api/oidc/clients/oauth2-proxy/secrets" \
            | jq -r '.[] | select(.isActive) | .id'); do
          if [ "$sid" != "$keep" ]; then
            curl -sf -X DELETE -H "$hdr" \
              "$api/oidc/clients/oauth2-proxy/secrets/$sid" >/dev/null
          fi
        done
      fi

      if [ ! -s ${stateDir}/cookie-secret ]; then
        umask 077
        openssl rand -base64 32 > ${stateDir}/cookie-secret
      fi
    '';
  };
  # Don't start oauth2-proxy until provisioning has succeeded (its secret
  # file does not exist otherwise).
  systemd.services.oauth2-proxy = {
    after = [ "pocket-id-sso-configure.service" ];
    requires = [ "pocket-id-sso-configure.service" ];
  };

  # --- nginx wiring ---------------------------------------------------------
  # oauth2-proxy's endpoints ride on the (public) pocket-id vhost...
  services.nginx.virtualHosts."${fqdn}".locations."/oauth2/" = {
    proxyPass = "http://127.0.0.1:4180";
    extraConfig = ''
      proxy_set_header X-Scheme                $scheme;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
    '';
  };

  # ...and everything on the protected vhost requires a Pocket ID session.
  # Same hostname (same cert, shared cookies), distinguished by port.
  services.nginx.virtualHosts."${fqdn}-protected" = {
    serverName = fqdn;
    listen = [
      {
        addr = "0.0.0.0";
        port = protectedPort;
        ssl = true;
      }
    ];
    onlySSL = true;
    sslCertificate = "${certDir}/${fqdn}.crt";
    sslCertificateKey = "${certDir}/${fqdn}.key";
    # Demo page: swap for a proxyPass/root of something real.
    root = pkgs.writeTextDir "index.html" ''
      <!doctype html>
      <html>
        <head><title>protected</title></head>
        <body>
          <h1>It worked.</h1>
          <p>This page is only visible with a Pocket ID session.</p>
        </body>
      </html>
    '';
    extraConfig = ''
      auth_request /oauth2/auth;
      error_page 401 = @redirectToAuth2ProxyLogin;
    '';
    locations."= /oauth2/auth" = {
      proxyPass = "http://127.0.0.1:4180/oauth2/auth";
      extraConfig = ''
        auth_request off;
        proxy_set_header X-Scheme $scheme;
        # $http_host (not $host) keeps the :${toString protectedPort} port
        proxy_set_header X-Auth-Request-Redirect $scheme://$http_host$request_uri;
        # auth subrequest must not forward the body
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
      '';
    };
    locations."@redirectToAuth2ProxyLogin" = {
      return = "307 https://${fqdn}/oauth2/start?rd=$scheme://$http_host$request_uri";
      extraConfig = ''auth_request off;'';
    };
  };
}
