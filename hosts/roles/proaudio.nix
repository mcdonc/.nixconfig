{pkgs, lib, ...}:
let
  rtcqs = pkgs.callPackage ../../pkgs/rtcqs.nix { };
  xruncounter = pkgs.callPackage ../../pkgs/xruncounter.nix { };

  # Stuff to get Arturia VSTs installed; presumes ASC has been installed in
  # ~/.wine via e.g.  "wine
  # ~/Downloads/Arturia_Software_Center__2_7_1_2466.exe" then run
  # arturia-software-center and install VSTs, then run arturia-add-vsts to sync
  # yabridge with the installed VSTs

  wine = "${pkgs.wineWowPackages.stable}/bin/wine";
  yabc = "${pkgs.yabridgectl}/bin/yabridgectl";

  arturia-sw-center = pkgs.writeShellScriptBin "arturia-sw-center" ''
    ${wine} $HOME/.wine/drive_c/Program\ Files\ \(x86\)/Arturia/Arturia\ Software\ Center/Arturia\ Software\ Center.exe
  '';
  arturia-add-vsts = pkgs.writeShellScriptBin "arturia-add-vsts" ''
    ${yabc} add $HOME/.wine/drive_c/Program\ Files/Common\ Files/VST3
    ${yabc} sync
  '';
in
{
  environment.systemPackages = with pkgs; [
    rtcqs
    xruncounter
    qpwgraph
    pavucontrol
    yabridge
    yabridgectl
    wineWowPackages.stable
    winetricks
    arturia-sw-center
    arturia-add-vsts
  ];

  # see https://github.com/musnix/musnix
  # Activate the performance CPU frequency scaling governor.
  # Set vm.swappiness to 10.
  # Set the following udev rules (enable high-precision timers, if they exist):
  #  KERNEL=="rtc0", GROUP="audio"
  #  KERNEL=="hpet", GROUP="audio"
  # Set the following PAM limits:
  #  @audio  -       memlock unlimited
  #  @audio  -       rtprio  99
  #  @audio  soft    nofile  99999
  #  @audio  hard    nofile  99999
  # Set environment variables to default install locations in NixOS:
  #  VST_PATH
  #  VST3_PATH
  #  LXVST_PATH
  #  LADSPA_PATH
  #  LV2_PATH
  #  DSSI_PATH
  # Allow users to install plugins in the following directories:
  #  ~/.vst
  #  ~/.vst3
  #  ~/.lxvst
  #  ~/.ladspa
  #  ~/.lv2
  #  ~/.dssi
  # musnix.alsaSql.enable does
  #  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];
  # musnix.rtirq.enable
  #  see https://wiki.linuxaudio.org/wiki/system_configuration

  musnix.enable = true;
  musnix.rtirq.enable = true;
  musnix.alsaSeq.enable = true;

  # additional udev stuff caught by rtcqs
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  services.udev = {
    extraRules = ''
      DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
    '';
  };
  environment.variables = {
    # override musnix to add $HOME/.vst to LXVST_PATH (for yabridge)
    LXVST_PATH =
      lib.mkForce "$HOME/.vst:$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
  };

  environment.etc = let
    json= pkgs.formats.json {};
  in {
    "pipewire/pipewire.d/92-low-latency.conf".source = json.generate
      "92-low-latency.conf" {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 32;
          default.clock.min-quantum = 32;
          default.clock.max-quantum = 32;
        };
      };
    # this doesn't work
    # "pipewire/jack.conf".source = json.generate "jack.conf" {
    #   jack.properties = {
    #     rt.prio = 99;
    #     node.latency = "32/48000";
    #     };
    #   };
  };
}
