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
    ../users/chrism
    ../users/tseaver
    ../users/alan
    ./roles/minimal.nix
    ./roles/journalwatch.nix
    ./roles/enfold/dads.nix
    ./roles/enfold/rag.nix
    ./roles/mailrelayer.nix
  ];
  environment.extraInit =
    let
      apikey-file = config.age.secrets."enfold-openai-api-key".path;
      cachix-file = config.age.secrets."enfold-cachix-authtoken".path;
    in
    ''
      umask 002
      export OPENAI_API_KEY=$(cat "${apikey-file}"|xargs)
      export CACHIX_AUTH_TOKEN=$(cat "${cachix-file}"|xargs)
    '';

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    11434
  ];
  networking.firewall.logRefusedConnections = false;

  services.fail2ban.enable = true;
  services.fail2ban.maxretry = 5;
  services.fail2ban.extraPackages = [ pkgs.ipset ];
  services.fail2ban.banaction = "iptables-ipset-proto6-allports";

  networking.hostId = "cd246164";
  networking.hostName = "enfold";
  system.stateVersion = "25.05";

  virtualisation.docker.enable = true;

  age.secrets."gandi-api" = {
    file = ../secrets/gandi-api.age;
    mode = "640";
    owner = "root";
    group = "acme";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "chrism@plope.com";
    defaults.dnsProvider = "gandiv5";
    defaults.environmentFile = config.age.secrets."gandi-api".path;
  };

  services.nginx = {
    enable = true;
    virtualHosts."pydio-token-service.repoze.org" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:6550/";
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

    virtualHosts."rag.repoze.org" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000/";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Host $host:$server_port;
          proxy_set_header X-Forwarded-Port $server_port;
        '';
      };
    };

  };

  users.users.nginx.extraGroups = [ "acme" ];

  boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce "1"; # redis

}
