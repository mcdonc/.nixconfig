{ ... }:
{
  systemd.services.dads = {
    description = "Dads processes";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = '''';
    script = ''
      cd /home/chrism/projects/enfold/dadsenv && ./bootstrap && devenv processes up
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "chrism";
      Group = "users";
      Environment = [];
    };
  };
  
}
