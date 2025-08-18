{ config, pkgs, lib, ... }:
{
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
      SLACK_NOTIFY_URL=$(cat "${config.age.secrets."enfold-slack-notify-url".path}"|xargs)
      export ENFOLD_GIT_USER=runyaga
      export ENFOLD_PAT=$(cat "${config.age.secrets."enfold-alan-pat".path}"|xargs)
      export OPENAI_API_KEY=$(cat "${config.age.secrets."enfold-openai-api-key".path}"|xargs)
      export NGPT_API_KEY=$(cat "${config.age.secrets."enfold-ngpt".path}"|xargs)
      export OAI_API_KEY=$(cat "${config.age.secrets."enfold-oai".path}"|xargs)
      export CACHIX_AUTH_TOKEN="$(cat "${config.age.secrets."mcdonc-cachix-authtoken".path}"|xargs)"
      DEVENV_CMD=/home/chrism/.nix-profile/bin/devenv
      mkdir -p /home/chrism/projects/enfold
      RAGENV_DIR=/home/chrism/projects/enfold/afsoc-rag
      if [ ! -d "$RAGENV_DIR" ]; then
        git clone "https://$ENFOLD_GIT_USER:$ENFOLD_PAT@github.com/enfold/afsoc-rag" $RAGENV_DIR
      fi
      cd $RAGENV_DIR
      git checkout -- .
      git fetch --all
      git checkout prod
      git pull
      python3 ./bootstrap --unattended
      oldtmpdir="$TMPDIR"
      mkdir -p "$RAGENV_DIR/tmp"
      export TMPDIR="$RAGENV_DIR/tmp" # we run out of space on /tmp via pip
      curl -X POST --data-urlencode "payload={\"channel\": \"#afsoc-rag\", \"username\": \"nixbot\", \"text\": \"rag.repoze.org processes starting\", \"icon_emoji\": \":ghost:\"}" "$SLACK_NOTIFY_URL"
      cat <<EOF > "$RAGENV_DIR/devenv.local.nix"
      { lib, config, ... }:
      {
        env.OLLAMA_BASE_URL = lib.mkForce "http://workshop:11434";
      }
      EOF
      $DEVENV_CMD --no-eval-cache shell -- flutterbuildandrunweb || \
      curl -X POST --data-urlencode "payload={\"channel\": \"#afsoc-rag\", \"username\": \"nixbot\", \"text\": \"rag.repoze.org processes did not start\", \"icon_emoji\": \":ghost:\"}" "$SLACK_NOTIFY_URL"
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      StartLimitBurst = 3; # Only allow 4 restarts in the interval
      StartLimitIntervalSec = 200;  # Count restarts within a 200s window
      User = "chrism";
      Group = "users";
    };
  };

}
