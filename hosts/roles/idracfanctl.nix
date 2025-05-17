{ pkgs, lib, ...}:

let
  idracfanctl = pkgs.stdenv.mkDerivation {
    name="idracfanctl";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "idracfanctl";
      rev = "64cd06130a9a3bc7299708005cbe350f1d33a1d7";
      sha256 = "sha256-RQlkPEUc3ntsltaMsVB72+MzwBoaMF4D5wKxs80orBc=";
    };
    buildInputs = [
      pkgs.makeWrapper
    ];
    installPhase = ''
      mkdir -p $out/bin
      cp idracfanctl.py $out/bin/idracfanctl.py
      makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
        --add-flags "$out/bin/idracfanctl.py" \
        --add-flags '--ipmitool="${pkgs.ipmitool}/bin/ipmitool"' \
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
        ${idracfanctl}/bin/idracfanctl --disable-pcie-cooling-response=1
      '';
      Restart = "always";
      User = "root";
      KillSignal = "SIGINT";
    };
  };
}
