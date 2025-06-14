{ pkgs, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    token = "123";
    clusterInit = true;
  };

}
