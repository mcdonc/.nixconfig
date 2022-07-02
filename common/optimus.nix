{ config, pkgs, ... }:

{

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    nvidia = {
      prime = {
        offload.enable = true; # enable to use intel gpu (hybrid mode)
        # sync.enable = true; # enable to use nvidia gpu (discrete mode)
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      modesetting.enable = false;
      powerManagement.enable = true;
    };

    # other opengl stuff is included via <nixos-hardware/common/cpu/intel> (including 
    # intel-media-driver and vaapiIntel)
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ vaapiVdpau ];
      driSupport = true;
      driSupport32Bit = true;
    };
  };
  
}
