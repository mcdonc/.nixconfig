{ ... }:
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
