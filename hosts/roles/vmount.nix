{pkgs, ...}:
let
  nixcentre = "192.168.1.103";
in
{
  fileSystems."/v" = {
    device = "//${nixcentre}/v";
    fsType = "cifs";
    options = [
      "username=guest"
      "uid=chrism"
      "gid=users"
      "x-systemd.automount"
      "noauto"
    ];
  };
}
