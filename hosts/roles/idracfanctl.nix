{ pkgs, lib, ...}:

let
  idracfanctl = pkgs.stdenv.mkDerivation {
    name="idracfanctl";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "idracfanctl";
      rev = "f7393a7cfcd4b72d48567e4088f179f51790e9aa";
      sha256 = "sha256-pIp9sODUO78D3u8+c/JUA0BWH4V8M7Ohf+DvLE7X5vA=";
    };
    buildInputs = [
      pkgs.makeWrapper
    ];
    installPhase = ''
      mkdir -p $out/bin
      cp idracfanctl.py $out/bin/idracfanctl.py
      makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
        --add-flags "$out/bin/idracfanctl.py"
    '';
    meta = with lib; {
      description = "Dell PowerEdge R730xd fan control";
      homepage = "https://github.com/mcdonc/idracfanctl";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in

{
  environment.systemPackages = [
    idracfanctl
  ];
  systemd.services.idracfanctl = {
    description = "Control Dell R730xd fans";
    after = [ "local-fs.target" ];
    before = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = ''
        ${idracfanctl}/bin/idracfanctl --disable-pcie-cooling-response=1 \
          --ipmitool="${pkgs.ipmitool}/bin/ipmitool"
      '';
      Restart = "always";
      User = "root";
      KillSignal = "SIGINT";
    };
  };
}
