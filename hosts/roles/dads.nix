{ config, ... }:
{
  age.secrets."enfold-pat" = {
    file = ../secrets/enfold-pat.age;
    mode = 600;
  };

  systemd.services.dads = {
    description = "Dads processes";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = '''';
    script = ''
      cd /home/chrism/projects/enfold/dadsenv && /home/chrism/.nix-profile/bin/devenv processes up
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "chrism";
      Group = "users";
      Environment = [
        "PYTHON_KEYRING_BACKEND=keyrings.alt.file.PlaintextKeyring"
        "ENFOLD_PAT_PATH=${config.age.secrets."enfold-pat".path};"
      ];
    };
  };

}
