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
    ../users/alan
    ./roles/minimal.nix
    ./roles/journalwatch.nix
    ./roles/dads
    ./roles/rag.nix
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
  services.fail2ban.extraPackages = [ pkgs.ipset ];
  services.fail2ban.banaction = "iptables-ipset-proto6-allports";
  services.fail2ban.jails = {
    "postfix-bruteforce" = ''
      enabled = true
      filter = postfix-bruteforce
      findtime = 600
      maxretry = 3
    '';
    "postfix-unresolving" = ''
      enabled = true
      filter = postfix-unresolving
      findtime = 600
      maxretry = 3
    '';
    "jupyterhub-bruteforce" = ''
      enabled = true
      filter = jupyterhub-bruteforce
      findtime = 600
      maxretry = 6
      backend = auto
      logpath = /var/log/nginx/access.log
    '';
  };

  networking.hostId = "cd246164";
  networking.hostName = "enfold";
  system.stateVersion = "25.05";

  virtualisation.docker.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "chrism@plope.com";
    defaults.dnsProvider = "gandiv5";
    defaults.environmentFile = "/var/lib/secrets/certs.secret";
  };

  # services.nginx = {
  #   enable = true;
  #   virtualHosts."pydio-token-service.repoze.org" = {
  #     forceSSL = true;
  #     enableACME = true;
  #     acmeRoot = null;
  #     locations."/" = {
  #       proxyPass = "http://127.0.0.1:6550/";
  #       extraConfig = ''
  #         proxy_set_header Host $host;
  #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #         proxy_set_header X-Forwarded-Proto $scheme;
  #         proxy_set_header X-Real-IP $remote_addr;
  #         proxy_set_header X-Forwarded-Host $host:$server_port;
  #         proxy_set_header X-Forwarded-Port $server_port;
  #       '';
  #     };
  #   };

  #   virtualHosts."rag.repoze.org" = {
  #     forceSSL = true;
  #     enableACME = true;
  #     acmeRoot = null;
  #     locations."/" = {
  #       proxyPass = "http://127.0.0.1:9000/";
  #       extraConfig = ''
  #         proxy_set_header Host $host;
  #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #         proxy_set_header X-Forwarded-Proto https;
  #         proxy_set_header X-Real-IP $remote_addr;
  #         proxy_set_header X-Forwarded-Host $host:$server_port;
  #         proxy_set_header X-Forwarded-Port $server_port;
  #       '';
  #     };
  #   };

  # };

  users.users.nginx.extraGroups = [ "acme" ];

  boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce "1"; # redis

}
