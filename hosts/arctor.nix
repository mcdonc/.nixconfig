{ lib, pkgs, inputs, system, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
    inputs.nixos-generators.nixosModules.all-formats
    ../users/chrism
    ../users/tseaver
    ./roles/minimal
    ./roles/doorserver.nix
  ];

  services.doorserver.enable = true;

  networking.hostId = "bd246190";
  networking.hostName = "arctor";
  system.stateVersion = "25.05";

  networking.firewall.allowedTCPPorts = [
    80 443
  ];

  virtualisation.docker.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "chrism@plope.com";
    defaults.dnsProvider = "gandi";
    environmentFile = "/var/lib/secrets/certs.secret";
  };

  services.nginx = {
    enable = true;
    virtualHosts."arctor.repoze.org" = {
      addSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/" = {
        root = "/home/chrism/static";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
    virtualHosts."arctor-root.repoze.org" = {
      addSSL = true;
      enableACME = false;
      locations."/" = {
        root = "/home/chrism/static/repoze";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
    virtualHosts."arctor-doorserver.repoze.org" = {
      forceSSL = true;
      enableACME = false;
      locations."/" = {
        proxyPass ="http://127.0.0.1:6544/";
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
    virtualHosts."lock802ws-arctor.repoze.org" = {
      forceSSL = true;
      enableACME = false;
      locations."/" = {
        proxyPass ="http://localhost:8001"; # worked under apache with ws://
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

  users.users.nginx.extraGroups = [ "acme" ];

  };

}
