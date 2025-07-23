{ config, pkgs, lib, ... }:
{
  age.secrets."enfold-pat" = {
    file = ../../../secrets/enfold-pat.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  age.secrets."enfold-openai-api-key" = {
    file = ../../../secrets/enfold-openapi-key.age;
    mode = "600";
    owner = "chrism";
    group = "wheel";
  };

  environment.systemPackages = [
    pkgs.curl
  ];

  systemd.services.rag = {
    description = "Rag processes";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.PATH = lib.mkForce "/run/wrappers/bin:/home/chrism/.nix-profile/bin:/nix/profile/bin:/home/chrism/.local/state/nix/profile/bin:/etc/profiles/per-user/chrism/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    environment.PYTHON_KEYRING_BACKEND = "keyrings.alt.file.PlaintextKeyring";

    preStart = '''';
    script = ''
      export ENFOLD_GIT_USER=mcdonc
      export ENFOLD_PAT=$(cat "${config.age.secrets."enfold-pat".path}"|xargs)
      export OPENAI_API_KEY=$(cat "${config.age.secrets."enfold-openai-api-key".path}"|xargs)
      mkdir -p /home/chrism/projects/enfold
      RAGENV_DIR=/home/chrism/projects/enfold/ragenv
      if [ ! -d "$RAGENV_DIR" ]; then
        git clone "https://mcdonc:$ENFOLD_PAT@github.com/mcdonc/ragenv.git" $RAGENV_DIR
      fi
      cd $RAGENV_DIR
      python3 ./bootstrap
      git pull
      oldtmpdir="$TMPDIR"
      mkdir -p "$RAGENV_DIR/tmp"
      export TMPDIR="$RAGENV_DIR/tmp" # we run out of space on /tmp via pip
      export TMPDIR="$oldtmpdir"
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
