{ pkgs, ... }:

let
  host = "keithmoon";
in

{
  # For mount.cifs, required unless domain name resolution is not needed.
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/v" = {
    device = "//${host}/v";
    fsType = "cifs";
    options = [
      "uid=chrism"
      "gid=users"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "noauto"
      "credentials=/etc/smb-secrets"
    ];
  };
}
