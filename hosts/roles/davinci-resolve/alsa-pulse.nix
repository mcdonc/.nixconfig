{ pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.alsa-plugins
  ];

  # Override the PipeWire-generated ALSA default to use the pulse plugin.
  # Resolve only speaks ALSA, and its capture is broken with the native
  # PipeWire ALSA plugin (upstream PipeWire issue #2870). Routing through
  # PipeWire's PulseAudio layer instead works correctly.
  environment.etc."alsa/conf.d/99-pipewire-default.conf".text = lib.mkForce ''
    pcm.!default {
        type pulse
    }

    ctl.!default {
        type pulse
    }
  '';
  environment.etc."alsa/conf.d/49-pulse-modules.conf".text = ''
    pcm_type.pulse {
      libs.native = ${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_pcm_pulse.so ;
    }
    ctl_type.pulse {
      libs.native = ${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_ctl_pulse.so ;
    }
  '';
  environment.etc."alsa/conf.d/50-pulseaudio.conf".source =
    "${pkgs.alsa-plugins}/share/alsa/alsa.conf.d/50-pulseaudio.conf";
}
