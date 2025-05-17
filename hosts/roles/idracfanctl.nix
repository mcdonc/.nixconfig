{ pkgs, lib, ...}:

let
  idracfanctl = pkgs.stdenv.mkDerivation {
    name="idracfanctl";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "idracfanctl";
      rev = "acb040f705332a3aa601c18f5e9815edaa9f71e9";
      sha256 = "sha256-sEVhywXO4H9NfoiVc1kWFyLdaZ4aAQEoPAPchjw4iuY=";
    };
    buildInputs = [
      pkgs.python3
      pkgs.ipmitool
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
