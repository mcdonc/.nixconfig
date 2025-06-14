{ lib, pkgs, ... }:

# logcheck itself will run at ${hour}:02, the tmpfile creation will run at
# ${hour}:00

let
  lcjc = pkgs.writeShellScriptBin "logcheck-journalctl" ''
    journalctl -o short-iso --since \
      "$(date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')"
  '';
  hour = "16";
  tmpfile = "/tmp/lcjc.txt";
in
{
  # see https://github.com/NixOS/nixpkgs/issues/240383
  nixpkgs.overlays = [(self: super: {
    logcheck = super.logcheck.overrideAttrs (old: {
      postInstall = "rm -r $out/etc/logcheck/logcheck.logfiles.d";
    });
  })];

  # all this tmpfile nonsense is needed because logcheck is unmaintained and
  # packaged poorly (cant use | at the beginning of the filename to pipe
  # output from journalctl)
  services.cron.systemCronJobs = [
    "0 ${hour} * * * logcheck ${lcjc}/bin/logcheck-journalctl > ${tmpfile}"
  ];
  services.logcheck.enable = true;
  services.logcheck.timeOfDay = hour;
  services.logcheck.level = lib.mkDefault "workstation";
  services.logcheck.files = lib.mkDefault [
    tmpfile
  ];
  services.logcheck.mailTo = lib.mkDefault "chrism@plope.com";
  services.logcheck.extraGroups = [
    "systemd-journal"
  ];

}
