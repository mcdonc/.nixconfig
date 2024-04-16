{pkgs, ... }:

{

  environment.systemPackages = [

    (
      pkgs.python311.pkgs.buildPythonApplication {
        pname = "dvtranscode";
        version = "0.0";
        propagatedBuildInputs = [
          pkgs.pciutils
          pkgs.ffmpeg-full
          pkgs.inotify-tools
        ];
        src = ./dvtranscode;
      }
    )

  ];

}
