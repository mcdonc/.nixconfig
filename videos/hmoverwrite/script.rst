NixOS 24: Convincing Home-Manager to Overwrite Existing Unmanaged Files
=======================================================================

- Companion to video at https://youtu.be/rS-Qtqb67nU

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Often you can put a new file in a new place to override existing
  configuration.  E.g. ``~/.local/share/applications`` can accept arbitrary
  ``.desktop`` files, and these will be preferred to more global ``.desktop``
  files that do the same thing.

- Or at least the set of desktop options is extended.

- For example::

    # add Olive for nvidia-offload
    xdg.desktopEntries = {
      olive = {
        name = "Olive Video Editor (via nvidia-offload)";
        genericName = "Olive Video Editor";
        exec = "nvidia-offload olive-editor";
        terminal = false;
        categories = [ "AudioVideo" "Recorder" ];
        mimeType = [ "application/vnd.olive-project" ];
        icon =  "org.olivevideoeditor.Olive";
      };
    };
    
- This causes a desktop entry to be findable for an ``nvidia-offload``-started
  version of the Olive video editor (it doesn't work reliably under offload
  mode if this isn't done).

- There are a lot of olive desktop files::

    sudo find / -name "*.desktop"|grep -i olive

- But ours gets put into ``/home/chrism/.nix-profile/share/applications`` as a
  result of the above config, and is just part of the pool of apps available to
  us.  Shows up slightly differently in search.

- But some locations are singletons.  E.g. ``~/config.autostart`` is the only
  place (as far as I know) to put ``.desktop`` files that represent programs
  that should be started at login time.

- Keybase installs a ``.desktop`` file into
  ``~/.config/autostart/keybase_autostart.desktop`` that doesn't work when you
  are in Nvidia ``sync`` mode because of some electron nonsense.

- We want home-manager to overwrite the file installed by keybase.  Out of the
  box, home-manager is careful not to do this.

- Here's the config file we want to put into autostart.  The only difference
  between the config file installed by keybase and this one is the
  ``--disable-gpu-sandbox`` flag passed to ``keybase-gui``::

    # default keybase_autostart.desktop doesn't run on NVIDIA in sync mode
    # without --disable-gpu-sandbox.
    xdg.configFile."autostart/keybase_autostart.desktop".text = ''
      [Desktop Entry]
      Comment[en_US]=Keybase Filesystem Service and GUI
      Comment=Keybase Filesystem Service and GUI
      Exec=env KEYBASE_AUTOSTART=1 keybase-gui --disable-gpu-sandbox
      GenericName[en_US]=
      GenericName=
      MimeType=
      Name[en_US]=Keybase
      Name=Keybase
      Path=
      StartupNotify=true
      Terminal=false
      TerminalOptions=
      Type=Application
      X-DBUS-ServiceName=
      X-DBUS-StartupType=
      X-KDE-SubstituteUID=false
      X-KDE-Username=
    '';
    
- If that's the only config we put in there, when we ran a rebuild, it would
  silently "fail".  That is, the unmanaged config file, which is in the way,
  would be untouched.

- Solution::

    # thanks to tejing on IRC for clueing me in to .force here: it will
    # overwrite any existing file.
    xdg.configFile."autostart/keybase_autostart.desktop".force = true;

- When ``.force`` is true, any existing file will be overwritten with the
  home-manager managed version of the file.

- This flag appears to be undocumented.
  
