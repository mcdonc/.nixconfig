{pkgs, ...}:

{
  environment.systemPackages = [
    pkgs.davinci-resolve-studio
  ];

  home-manager.users.chrism = {
    xdg.desktopEntries = {
      davinci-nvidia = {
        name = "DaVinci Resolve Studio (via nvidia-offload)";
        genericName = "DaVinci Resolve Video Editor";
        exec = "nvidia-offload davinci-resolve-studio";
        terminal = false;
        categories = [ "AudioVideo" "Recorder" ];
        mimeType = [ "application/x-resolveproj" ];
        icon = ./DV_Resolve.png;
      };
    };
  };
}
