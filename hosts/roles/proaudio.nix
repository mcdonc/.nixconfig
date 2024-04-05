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

  #services.pipewire.wireplumber.enable = true;

  environment.variables = {
    # override musnix to add $HOME/.vst to LXVST_PATH (for yabridge)
    LXVST_PATH = "$HOME/.vst:$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
  };

  environment.etc."pipewire/pipewire.conf.d/92-low-latency.conf" = {
    text = ''
      context.properties = {
        default.clock.quantum = 32
      }
      jack.properties = {
        node.quantum = 32/48000
      }
    '';
  };
}
