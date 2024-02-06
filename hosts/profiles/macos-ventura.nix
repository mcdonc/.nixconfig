{ bigger-darwin, cores ? 4, mem ? "12G", ...}:
{
  services.macos-ventura = {
    enable = true;
    package = bigger-darwin;
    openFirewall = true;
    vncListenAddr = "0.0.0.0";
    cores = cores;
    mem = mem;
  };
}
