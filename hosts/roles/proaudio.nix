{pkgs, lib, ...}:
let
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
  musnix.enable = true;
  musnix.rtirq.enable = true;
  musnix.rtcqs.enable = true;
  musnix.alsaSeq.enable = true;

  services.pipewire.wireplumber.enable = true;

  environment.variables = {
    # override musnix to add $HOME/.vst to LXVST_PATH (for yabridge)
    LXVST_PATH = "$HOME/.vst:$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
  };

  # Optimized for the Edirol UA-25 USB capture device
  #
  # See https://alsa.opensrc.org/Edirol_UA-25#Advanced_Alsa_configuration
  # for info about what UA-25 switches do
  #
  # Edirol UA-25 must be set to ADVANCE, 48K to support a quantum of 64;
  # if ADVANCE is off (or presumably if set to 44.1K; ADVANCE off implies 44.1K)
  # there is crackling at quantums below 128, presumably due to the upscaling
  # that pipewire does to 48K.  Crackling at 32 no matter what.

  environment.etc."pipewire/pipewire.conf.d/92-low-latency.conf" = {
    text = ''
      context.properties = {
        default.clock.quantum = 64
        default.clock.min-quantum = 64
        default.clock.max-quantum = 64
      }
      jack.properties = {
        node.quantum = 64/48000
      }
    '';
  };

  # No settings at all seems better than any setting I've tried below

  # environment.etc."wireplumber/main.lua.d/52-usb-ua25-config.lua" = {
  #   text = ''
  #     rule = {
  #       matches = {
  #         {
  #           -- Matches all sources.
  #           { "node.name", "matches", "alsa_input.usb-Roland_EDIROL_UA-25-00.*" },
  #         },
  #         {
  #           -- Matches all sinks.
  #           { "node.name", "matches", "alsa_output.usb-Roland_EDIROL_UA-25-00.*" },
  #         },
  #       },
  #       apply_properties = {
  #         ["api.alsa.period-size"]   = 256,
  #         ["api.alsa.period-num"]    = 3,
  #       },
  #     }

  #     table.insert(alsa_monitor.rules, rule)
  #   '';
  # };
}
