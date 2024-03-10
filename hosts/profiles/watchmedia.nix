{pkgs, ...}:
let
  dvtranscode = pkgs.callPackage ../../pkgs/dvtranscode.nix { };
in
{
  systemd.services.watchmedia = {
    enable = true;
    description = "Transcode the Resolve media directory in the background.";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    restartIfChanged = true;
    serviceConfig = {
      ExecStart = ''
        ${dvtranscode}/bin/dvwatchmedia /v/media
      '';
    };
  };

}
