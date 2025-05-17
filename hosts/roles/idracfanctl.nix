{ pkgs, lib, ...}:

let
  idracfanctl = pkgs.stdenv.mkDerivation {
    name="idracfanctl";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "idracfanctl";
      rev = "ce3343b47776fcba53ca15db7c522b1e46fb372a";
      sha256 = "sha256-XDEHS/LsSXy6+2+VOclk/r5C8M7lD+QmgYxHDbZcD5M=";
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
