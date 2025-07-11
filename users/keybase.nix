{ pkgs, pkgs-kb-bumpversion, ... }:

let
  # switch to pkgs-kb-bumpversion and switch to explicit config
  # if kb-pkgs craps out
  kb-pkgs = pkgs-kb-bumpversion;
in

{
  # thanks to tejing on IRC for clueing me in to .force here: it will
  # overwrite any existing file.
  xdg.configFile."autostart/keybase_autostart.desktop".force = true;

  # default keybase_autostart.desktop doesn't run on NVIDIA in sync mode
  # without --disable-gpu-sandbox.

  xdg.configFile."autostart/keybase_autostart.desktop".text = ''
    [Desktop Entry]
    Comment[en_US]=Keybase Filesystem Service and GUI
    Comment=Keybase Filesystem Service and GUI
    Exec=env KEYBASE_AUTOSTART=1 ${kb-pkgs.keybase-gui}/bin/keybase-gui --disable-gpu-sandbox
    GenericName[en_US]=
    GenericName=
    MimeType=
    Name[en_US]=Keybase
    Name=Keybase
    StartupNotify=true
    Terminal=false
    TerminalOptions=
    Type=Application
    X-DBUS-ServiceName=
    X-DBUS-StartupType=
    X-KDE-SubstituteUID=false
    X-KDE-Username=
  '';

  home.packages = with kb-pkgs; [
    keybase-gui
    keybase
  ];

  #services.keybase.enable = true;
  #services.kbfs.enable = true;

  systemd.user.services.keybase = {
    Unit.Description = "Keybase service";

    Service = {
      ExecStart = "${kb-pkgs.keybase}/bin/keybase service --auto-forked";
      Restart = "on-failure";
      PrivateTmp = true;
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.kbfs = {
    Unit = {
      Description = "Keybase File System";
      Requires = [ "keybase.service" ];
      After = [ "keybase.service" ];
    };

    Service =
      let
        mountPoint = ''"%h/keybase"'';
      in
      {
        Environment = "PATH=/run/wrappers/bin KEYBASE_SYSTEMD=1";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
        ExecStart = "${kb-pkgs.kbfs}/bin/kbfsfuse ${mountPoint}";
        ExecStopPost = "/run/wrappers/bin/fusermount -u ${mountPoint}";
        Restart = "on-failure";
        PrivateTmp = true;
      };

    Install.WantedBy = [ "default.target" ];
  };

}
