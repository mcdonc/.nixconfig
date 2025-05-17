{ pkgs, lib, ...}:

let
  idracfanctl = pkgs.stdenv.mkDerivation {
    name="idracfanctl";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "idracfanctl";
      rev = "5c57dfe40a1dccd79c70762bfcd4b4dda80b1a35";
      sha256 = "sha256-skrXeqI4O/mdtTNYsn6jqe1MDKiJDBZZjAnIdXBAigg=";
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
      description = "Dell poweredge fan control";
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
    description = "Control Dell R730XD fans";
    after = [ "local-fs.target" ];
    before = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = ''
        ${idracfanctl}/bin/idracfanctl --disable-pcie-cooling-response=1
      '';
      Restart = "always";  # Restart the service if it crashes
      User = "root";  # Run the service as root
    };
  };
}
