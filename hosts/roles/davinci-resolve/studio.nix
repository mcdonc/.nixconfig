{ pkgs, lib, pkgs-2411, ... }:

{

  # 25.05 gjs 1.82.2 tests fail for i686
  # 24.11 uses gjs 1.82.1; these tests also fail on i686 when only overriding
  # source

  # nixpkgs.overlays = [
  #   (self: super: {
  #     gjs = super.gjs.overrideAttrs (oldAttrs: {
  #       doCheck = false;
  #     });
  #   })
  # ];

  environment.systemPackages = [
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
