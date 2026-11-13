{ pkgs, ... }:
{

  # see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/resolved.nix
  # man resolved.conf
  # man systemd-resolved.service
  # https://unix.stackexchange.com/questions/482348/how-single-label-dns-lookup-requests-are-handled-by-systemd-resolved

  services.resolved = {
    enable = true;
    # (see man resolved.conf)
    settings.Resolve = {
      DNSSEC = "false";
      Domains = [ "~." ]; # "use as default interface for all requests"
      DNSOverTLS = "opportunistic";
      # MulticastDNS=yes lets resolved publish and resolve mdns hostname
      # records (=resolve lets it only resolve mDNS names)
      MulticastDNS = "yes";
      LLMNR = "true"; # handle single-name hostnames
    };
  };

  # Override Tailscale's DNS settings on the tailscale0 interface to use
  # the local MagicDNS proxy (100.100.100.100) and set routing domains
  # so that bare tailnet hostnames (e.g. "ping bizon") resolve correctly.
  # Runs in a loop because tailscaled periodically resets these settings.
  # See: https://github.com/tailscale/tailscale/issues/16558
  systemd.services.tailscale-dns-fix = {
    description = "Fix Tailscale DNS to use local MagicDNS proxy";
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
    };
    path = [ pkgs.jq ];
    script = ''
      # Wait for tailscale to come online
      until ${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -q Online; do
        sleep 2
      done

      # Get the tailnet's MagicDNS suffix (e.g. tail33f8f4.ts.net)
      suffix=$(${pkgs.tailscale}/bin/tailscale status --json \
        | jq -r '.MagicDNSSuffix')

      while true; do
        current_dns=$(${pkgs.systemd}/bin/resolvectl dns tailscale0 2>/dev/null)
        if ! echo "$current_dns" | ${pkgs.gnugrep}/bin/grep -q "100.100.100.100"; then
          ${pkgs.systemd}/bin/resolvectl dns tailscale0 100.100.100.100
          # search domain (without ~) for name expansion: bizon -> bizon.$suffix
          # routing domain (~ts.net) to direct *.ts.net queries here
          ${pkgs.systemd}/bin/resolvectl domain tailscale0 "$suffix" ~ts.net
        fi
        sleep 30
      done
    '';
  };

  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "8.8.8.8#dns.google"
    "1.0.0.1#cloudflare-dns.com"
    "8.8.4.4#dns.google"
    "2606:4700:4700::1111#cloudflare-dns.com"
    "2001:4860:4860::8888#dns.google"
    "2606:4700:4700::1001#cloudflare-dns.com"
    "2001:4860:4860::8844#dns.google"
  ];

}
