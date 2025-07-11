{ config, pkgs, lib, ... }:
{
  age.secrets."enfold-pat" = {
    file = ../../secrets/enfold-pat.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  age.secrets."enfold-pydio-service-token" = {
    file = ../../secrets/enfold-pydio-service-token.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  environment.systemPackages = [
    pkgs.curl
  ];

  systemd.services.dads = {
    description = "Dads processes";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = '''';
    script = ''
      export PATH="/run/current-system/sw/bin:$PATH"
      export ENFOLD_PAT=$(cat "${config.age.secrets."enfold-pat".path}"|xargs)
      export PYDIO_SERVICE_TOKEN=$(cat "${config.age.secrets."enfold-pydio-service-token".path}"|xargs)
      mkdir -p /home/chrism/projects/enfold
      DADSENV_DIR=/home/chrism/projects/enfold/dadsenv
      if [ ! -d "$DADSENV_DIR" ]; then
        ${lib.getExe pkgs.git} clone "https://mcdonc:$ENFOLD_PAT@github.com/mcdonc/dadsenv.git" $DADSENV_DIR
      fi
      cd $DADSENV_DIR
      ${lib.getExe pkgs.python3} ./bootstrap
      ${lib.getExe pkgs.git} pull
      pushd afsoc-dads && ${lib.getExe pkgs.git} pull && popd
      DEVENV_CMD=/home/chrism/.nix-profile/bin/devenv
      DADSPATH=/home/chrism/dads-cli/dads
      if [ ! -f "$DADSPATH" ]; then
        $DEVENV_CMD shell -- dadsbuild
      fi
      echo "wuzzup"
      exec $DEVENV_CMD processes up
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "chrism";
      Group = "users";
      Environment = [
        "PYTHON_KEYRING_BACKEND=keyrings.alt.file.PlaintextKeyring"
      ];
    };
  };

}
