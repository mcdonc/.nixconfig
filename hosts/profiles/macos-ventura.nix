{ bigger-darwin, ... }:
{
  services.macos-ventura = {
    enable = true;
    package = bigger-darwin;
    openFirewall = true;
    vncListenAddr = "0.0.0.0";
    cores = 4;
    mem = "16G";
  };
}
