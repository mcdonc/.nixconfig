{ pkgs, pkgs-2411, ... }:

{
  environment.systemPackages = [
    # 25.05 gjs tests fail (1p4sqldwigyphn2laza1ikxwpxg5hqx0-gjs-1.84.2.drv)
    # 24.11 uses gjs 1.82.1
    pkgs-2411.davinci-resolve-studio
  ];

  home-manager.users.chrism = {
    xdg.desktopEntries = {
      davinci-nvidia = {
        name = "DaVinci Resolve Studio (via nvidia-offload)";
        genericName = "DaVinci Resolve Video Editor";
        exec = "nvidia-offload davinci-resolve-studio";
        terminal = false;
        categories = [
          "AudioVideo"
          "Recorder"
        ];
        mimeType = [ "application/x-resolveproj" ];
        icon = ./DV_Resolve.png;
      };
    };
  };
}
