{ ... }:
{
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
      ];
    };
  };
  
}
