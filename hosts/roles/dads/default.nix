{ config, pkgs, lib, ... }:
{
  age.secrets."enfold-pat" = {
    file = ../../../secrets/enfold-pat.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  age.secrets."enfold-pydio-service-token" = {
    file = ../../../secrets/enfold-pydio-service-token.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  age.secrets."enfold-view-user-password" = {
    file = ../../../secrets/enfold-view-user-password.age;
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
    environment.PATH = lib.mkForce "/run/wrappers/bin:/home/chrism/.nix-profile/bin:/nix/profile/bin:/home/chrism/.local/state/nix/profile/bin:/etc/profiles/per-user/chrism/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    environment.PYTHON_KEYRING_BACKEND = "keyrings.alt.file.PlaintextKeyring";

    preStart = '''';
    script = ''
      export ENFOLD_PAT=$(cat "${config.age.secrets."enfold-pat".path}"|xargs)
      export PYDIO_SERVICE_TOKEN=$(cat "${config.age.secrets."enfold-pydio-service-token".path}"|xargs)
      export VIEW_USER_PASSWORD=$(cat "${config.age.secrets."enfold-view-user-password".path}"|xargs)
      mkdir -p /home/chrism/projects/enfold
      DADSENV_DIR=/home/chrism/projects/enfold/dadsenv
      if [ ! -d "$DADSENV_DIR" ]; then
        git clone "https://mcdonc:$ENFOLD_PAT@github.com/mcdonc/dadsenv.git" $DADSENV_DIR
      fi
      cd $DADSENV_DIR
      python3 ./bootstrap
      git pull
      pushd afsoc-dads && git pull && popd
      DEVENV_CMD=/home/chrism/.nix-profile/bin/devenv
      DADSPATH=/home/chrism/dads-cli/dads
      oldtmpdir="$TMPDIR"
      mkdir "$DADSENV_DIR/tmp"
      export TMPDIR="$DADSENV_DIR/tmp" # we run out of space on /tmp via pip
      if [ ! -f "$DADSPATH" ]; then
        $DEVENV_CMD shell -- true
      fi
      export TMPDIR="$oldtmpdir"
      echo "wuzzup"
      exec $DEVENV_CMD processes up
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "chrism";
      Group = "users";
    };
  };

}
