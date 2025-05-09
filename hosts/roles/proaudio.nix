{pkgs, ...}:
let
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
  adevices = pkgs.writeShellScriptBin "adevices"
    (builtins.readFile ./adevices.sh);
in
{
  imports = [
    ../../pkgs/xruncounter.nix
  ];
  
  environment.variables = {
    # override musnix to add $HOME/.vst to LXVST_PATH (for yabridge)
    LXVST_PATH = "$HOME/.vst:$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
  };

  environment.systemPackages = with pkgs; [
    zita-alsa-pcmi # alsa_delay
    jack-example-tools # jack_iodelay

    qpwgraph
    pavucontrol
    yabridge
    yabridgectl
    wineWowPackages.stable
    winetricks
    arturia-sw-center
    arturia-add-vsts
    adevices
  ];

  # see https://github.com/musnix/musnix
  musnix.enable = true;
  musnix.rtirq.enable = true;
  musnix.rtcqs.enable = true;
  musnix.alsaSeq.enable = true;

  # Optimized for the Edirol UA-25 USB capture device
  #
  # See https://alsa.opensrc.org/Edirol_UA-25#Advanced_Alsa_configuration
  # for info about what UA-25 switches do
  #
  # Edirol UA-25 must be set to ADVANCE, 48K to support a quantum of 64 & less;
  # if ADVANCE is off (or presumably if set to 44.1K; ADVANCE off implies 44.1K)
  # there is crackling at quantums below 128, presumably due to the upscaling
  # that pipewire does to 48K.  There is crackling at 32 no matter what.
  #
  # alsa_delay hw:3,0 hw:3,0 48000 128 2 1 1
  #
  #   344.811 frames      7.184 ms
  #
  # For UA-25, Ardour ALSA calibration reports with quantum at 64:
  #
  #  Detected roundtrip latency: 473 samples (9.854ms)
  #  Systemic latency: 345 samples (7.188ms)
  #
  # jack_iodelay (jd_out to playback, jd_in to capture)
  #
  # 328.800 frames      6.850 ms total roundtrip latency
  # 	extra loopback latency: 200 frames
	#   use 100 for the backend arguments -I and -O
  #
  # see https://discourse.ardour.org/t/how-does-pipewire-perform-with-ardour/107381/12
  #
  # pw-cli
  # set-param 55 ProcessLatency {rate: 345}
  # set-param 56 ProcessLatency {rate: 345}
  # enum-params 55 Spa:Enum:ParamId:Latency
  # enum-params 55 Spa:Enum:ParamId:ProcessLatency
  # enum-params 56 Spa:Enum:ParamId:Latency
  # enum-params 56 Spa:Enum:ParamId:ProcessLatency
  #
  # pw-jack jack_lsp -l

  # wanted in 92-low-latency:
  #
  # context.properties = {
  #   default.clock.quantum = 256
  #   default.clock.min-quantum = 256
  #   default.clock.max-quantum = 512
  # }
  # jack.properties = {
  #   node.quantum = 256/48000
  # }


  # services.pipewire.extraConfig.pipewire."92-low-latency" = {
  #   context.properties = {
  #     default.clock.quantum = 256;
  #     default.clock.min-quantum = 256;
  #     default.clock.max-quantum = 512;
  #   };
  #   jack.properties = {
  #     node.quantum = "256/48000";
  #   };
  # };

  # services.pipewire.wireplumber.enable = true;

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
  #         -- latency.internal.rate is same as ProcessLatency
  #         ["latency.internal.rate"] = 76,
  #         ["api.alsa.period-size"]   = 256,
  #         ["api.alsa.period-num"]   = 3,
  #         -- ["api.alsa.disable-batch"]   = true,
  #       },
  #     }

  #     table.insert(alsa_monitor.rules, rule)
  #   '';
  # };

}
