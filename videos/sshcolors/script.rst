NixOS 48: Automatically Change Terminal Color When You SSH (home-manager/gnome-terminal/zsh)
============================================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

- This definitely isn't a NixOS thing: any system running home-manager under
  Linux should be able to make use of this.

- Ugly hack-job and very config-specific but very reliable.

- And  before anyone mentions ``kitty``, yes I know about it.

- Nicety: whenever you ssh to a remote system, automatically change the
  background color of the terminal you're sshing from, and change it back when
  the ssh connection ends.  Not really a Nix thing, but home-manager makes it
  possible to do it once and never need to think about it again.

- Note that I say "background color" but what I mean is "any setting
  representable in a gnome-terminal profile".  This makes this hack specific to
  gnome-terminal.  It is also X-specific (probably wont work under Wayland).  I
  also mention some zsh-specific configuration here.

  You'll have to adapt if you don't use gnome-terminal, X, and zsh, but
  hopefully you'll get the gist of what's happening under the hood so that
  should be possible.

- For this to work repeatably, you need to set up gnome-terminal profiles via
  home-manager.  In your home-manager config::
  
      programs.gnome-terminal = {
        enable = true;
        showMenubar = false;

        profile.b1dcc9dd-5262-4d8d-a863-c897e6d979b9 = {
          default = true;
          visibleName = "1grey";
          colors = {
            backgroundColor = "#1C2023";
          };
        };

        profile.ec7087d3-ca76-46c3-a8ec-aba2f3a65db7 = {
          default = false;
          visibleName = "2blue";
          colors = {
            backgroundColor = "#00008E";
          };
       };

       profile.ea1f3ac4-cfca-4fc1-bba7-fdf26666d188 = {
         default = false;
         visibleName = "3black";
          colors = {
            backgroundColor = "#00008E";
          };
       };
      };

- Prefix the visibleNames with numbers so they don't move around when you add
  or remove one, which is required by a step we haven't yet reached.  Generate
  new profile ids using ``uuidgen``.
  
- My profiles contain much more per-profile configuration (such as palette,
  font, etc), see
  https://github.com/mcdonc/.nixconfig/blob/master/users/chrism/hm.nix for the
  whole picture.

- The ``xdotool`` tool allows us to emulate sending keystrokes and other X
  input signals.  ``xdotool key Shift-F10 r 2`` sends Shift-F10 (the equivalent
  of a right-click in gnome-terminal), then emulates typing the "r" key, which
  activates the profiles menu, then emulates typing another key, which is a
  number representing the profile I'd like to select.  For example, when I type
  into gnome-terminal ``xdotool key Shift-F10 r 2`` it will select the
  gnome-terminal profile numbered 2 in the list, which, in my case, selects a
  profile I've created named ``2blue`` and makes my background terminal color
  blue.

- To automate the change of profile when using ssh to attach to remote servers,
  we need to create a shell script that wraps ssh and we need to install
  ``xdotool``.  This is what my home-manager configuration looks like to do
  this (note that this is under a home-manager flakes-based NixOS-module
  configuration, yours might be slightly different)::

    let
      ssh-chcolor = pkgs.writeShellScriptBin "ssh-chcolor" ''
        function chcolor(){
          # emulates right-clicking and selecting a numbered profile.
          # hide output if it fails (if you're ssh'ed in, for example, and
          # use ssh recursively).  --clearmodifiers ignores any
          # modifier keys you're physically holding before sending the command
          xdotool key --clearmodifiers Shift+F10 r $1 > /dev/null 2>&1
        }
        # change the profile; ssh; change the profile back to default
        chcolor 2; ssh $@; chcolor 1
      '';
    in
    {
      home.packages = with pkgs; [ ssh-chcolor xdotool ];
      ...

- It changes to the gnome-terminal profile that is blue, ssh-s to whatever,
  then when the connection ends, sets the profile back to my default one, which
  is grey.

- Then I arrange for this script to be called instead of my normal ``ssh``
  command by using an alias in my ``zsh`` home-manager config::

    programs.zsh = {
      enable = true;
      shellAliases = {
        ssh = "${ssh-chcolor}/bin/ssh-chcolor";
      };
    };

- Activate the config, Bob, uncle.
