{
  lib,
  pkgs,
  inputs,
  system,
  config,
  ...
}:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
    inputs.nixos-generators.nixosModules.all-formats
    inputs.mailserver.nixosModule
    ../users/chrism
    ../users/tseaver
    ./roles/minimal.nix
    ./roles/lock802/doorserver.nix
    ./roles/journalwatch.nix
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];
  networking.firewall.logRefusedConnections = false;

  services.fail2ban.enable = true;
  services.fail2ban.maxretry = 5;

  services.doorserver.enable = true;
  services.doorserver.wssecret-file = config.age.secrets."wssecret".path;
  services.doorserver.doors-file = config.age.secrets."doors".path;
  services.doorserver.passwords-file = config.age.secrets."passwords".path;

  age.secrets."passwords" = {
    file = ../secrets/passwords.age;
    mode = "600";
  };
  age.secrets."doors" = {
    file = ../secrets/doors.age;
    mode = "600";
  };
  age.secrets."wssecret" = {
    file = ../secrets/wssecret.age;
    mode = "600";
  };
  age.secrets."chris-mail-password-bcrypt" = {
    file = ../secrets/chris-mail-password-bcrypt.age;
    mode = "600";
  };

  networking.hostId = "bd246190";
  networking.hostName = "arctor";
  system.stateVersion = "25.05";

  virtualisation.docker.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "chrism@plope.com";
    defaults.dnsProvider = "gandiv5";
    defaults.environmentFile = "/var/lib/secrets/certs.secret";
  };

  services.nginx = {
    enable = true;
    virtualHosts."arctor.repoze.org" = {
      addSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        root = "/srv/static";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
    virtualHosts."repoze.org" = {
      addSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        root = "/srv/static/repoze";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
    virtualHosts."lock802.repoze.org" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:6544/";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Host $host:$server_port;
          proxy_set_header X-Forwarded-Port $server_port;
        '';
      };
    };
    virtualHosts."lock802ws.repoze.org" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://localhost:8001"; # worked under apache with ws://
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Host $host:$server_port;
          proxy_set_header X-Forwarded-Port $server_port;
        '';
      };
    };

  };

  users.users.nginx.extraGroups = [ "acme" ];

  mailserver =
    let
      passfile = config.age.secrets."chris-mail-password-bcrypt".path;
    in
    {
      enable = true;
      openFirewall = true;
      fqdn = "arctor.repoze.org";
      domains = [ "repoze.org" ];
      enableImap = false;
      enableImapSsl = false;
      # To create the password hashes, use
      # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'

      loginAccounts = {
        "chrism@repoze.org" = {
          hashedPasswordFile = passfile;
          aliases = [
            "@repoze.org" # allow sending from any mail at repoze.org
          ];
          catchAll = [
            "repoze.org" # receive all mails destined for repoze.org
          ];
        };
      };

      forwards = {
        "chrism@repoze.org" = "chrism@plope.com";
      };

      certificateScheme = "acme"; # managed by service.ngnix above
    };

    # allow sender to be any domain if sasl-auth submitted
    services.postfix.config.smtpd_sender_restrictions = lib.mkForce "
      permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination";

    # allow recipient to be any domain if sasl-auth submitted
    services.postfix.config.smtpd_recipient_restrictions = lib.mkForce "
      permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination";

    services.postfix.extraAliases = ''
      default: root
      root: chrism@repoze.org
    '';

    services.postfix.canonical = ''
      /^([^@]+)(@(arctor|arctor\.repoze\.org))?$/    ''${1}@repoze.org
      /^([^@]+)(@([^.@]+(\.localdomain)?)?)?$/       ''${1}@repoze.org
    '';

    services.postfix.config = {
      recipient_canonical_maps = "regexp:/etc/postfix/canonical";
      sender_canonical_maps = "regexp:/etc/postfix/canonical";
    };

  #https://bkiran.com/blog/using-nginx-in-nixos

  # postfix # XXX ask tres
  # redis # XXX ask tres
  # containerd # climo container images need to be migrated

  # rpi: https://blog.janissary.xyz/posts/nixos-install-custom-image
}
