{
  bigger-darwin,
  cores ? 4,
  mem ? "12G",
  enable ? true,
  ...
}:
{
  services.macos-ventura = {
    enable = enable;
    package = bigger-darwin;
    #openFirewall = true;
    #vncListenAddr = "0.0.0.0";
    cores = cores;
    mem = mem;
  };
}
