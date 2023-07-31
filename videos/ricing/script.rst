NixOS 49: Ricing the Terminal (zsh/p10k/fzf/shell-genie)
========================================================

- Companion to video at https://www.youtube.com/watch?v=R2-HOeTlcyE

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

- See the a full ``home-manager`` configuration with the features demonstrated
  here at https://github.com/mcdonc/.nixconfig/blob/master/users/chrism/hm.nix

Script
------

- This video is super unoriginal in general, but these are the steps that get
  rice you covet from having seen all the other Linux terminal ricing videos,
  but within NixOS.

- It assumes you're using ``home-manager`` and ``zsh``.

Powerlevel 10k
--------------

- Zsh prompt theme plus various niceties, such as git status
  within the prompt and many other things I don't really use.

- See https://www.youtube.com/watch?v=OXKhv2rXLBo for an overview of some of
  the features of P10k.

- No nerdfonts in my config, so no fancy icons.

- home-manager zsh config::

    programs.zsh = {
      ... elided ...
      initExtra = ''
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      ''
      zplug = {
        enable = true;
        plugins = [{
          name = "romkatv/powerlevel10k";
          tags = [ "as:theme" "depth:1" ];
        }];
      };
    };

- Bit of a dance generating a ``p10k.zsh`` file via ``p10k configure`` becuase
  it wants to write to ``~/config/.zshrc`` which is probably home-manager
  controlled.  Just ignore the warning and generate the .p10k file.

- Once you get it generated, you can move it into your version controlled Nix
  config and put it in place by adding to your home-manager config::

    home.file.".p10k.zsh" = {
      source = ./.p10k.zsh;
      executable = true;
    };

fzf
---

- Fuzzy finding within files/directories/history on the command line.  See
  https://www.freecodecamp.org/news/fzf-a-command-line-fuzzy-finder-missing-demo-a7de312403ff/
  for a demo.

- Within your home-manager config::

    home.packages = with pkgs; [
      # fd is an unnamed dependency of fzf
      fd
    ];

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;
    
- The following ``programs.zsh`` option was necessary for me for ``**<TAB>`` to
  work, but could be unnecessary for you::

    initExtra = ''
        bindkey '^I' fzf-completion
    ''

shell-genie
-----------

- Script to get AI-generated command-line suggestions.

- https://github.com/dylanjcastillo/shell-genie

- Author runs a free service to generate responses, but you can also use
  Chat-GPT 3.5.

- In your home-manager config::

    home.packages = with pkgs; [
       shell-genie
    ];

- Then in a terminal after a rebuild::

   ``shell-genie init``

- ``shell-genie ask "list all files in a directory greater than 50MB in size"``

Bash-alike
----------

- I used ``bash`` for 25+ years before I started to use ``zsh`` and these zsh
  options (under your ``programs.zsh`` configuration) make it a lot more
  bashy, or at least Ubuntu-bashy::

    initExtra = ''
      setopt interactive_comments bashautolist nobeep nomenucomplete noautolist

      ## Keybindings section
      bindkey -e
      bindkey '^[[7~' beginning-of-line                   # Home key
      bindkey '^[[H' beginning-of-line                    # Home key
      # [Home] - Go to beginning of line
      if [[ "''${terminfo[khome]}" != "" ]]; then
      bindkey "''${terminfo[khome]}" beginning-of-line
      fi
      bindkey '^[[8~' end-of-line                         # End key
      bindkey '^[[F' end-of-line                          # End key
      # [End] - Go to end of line
      if [[ "''${terminfo[kend]}" != "" ]]; then
      bindkey "''${terminfo[kend]}" end-of-line
      fi
      bindkey '^[[2~' overwrite-mode                      # Insert key
      bindkey '^[[3~' delete-char                         # Delete key
      bindkey '^[[C'  forward-char                        # Right key
      bindkey '^[[D'  backward-char                       # Left key
      bindkey '^[[5~' history-beginning-search-backward   # Page up key
      bindkey '^[[6~' history-beginning-search-forward    # Page down key
      # Navigate words with ctrl+arrow keys
      bindkey '^[Oc' forward-word
      bindkey '^[Od' backward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word
      # delete previous word with ctrl+backspace
      bindkey '^H' backward-kill-word
    ''
 
