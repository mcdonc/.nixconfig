{ pkgs, pkgs-2411, ... }:

{
  environment.systemPackages = [
    pkgs-2411.davinci-resolve
  ];

  home-manager.users.chrism = {
    xdg.desktopEntries = {
      davinci-nvidia = {
        name = "DaVinci Resolve Free (via nvidia-offload)";
        genericName = "DaVinci Resolve Video Editor";
        exec = "nvidia-offload davinci-resolve";
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
