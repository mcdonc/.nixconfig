args@{ pkgs, lib, config, ... }:

let

  remoterebuild = pkgs.writeShellScriptBin "remoterebuild" ''
    cd /etc/nixos
    fqdn="$1"
    nixos-rebuild-ng switch --flake ".#''${fqdn%%.*}" \
      --target-host chrism@$fqdn --ask-sudo-password
  '';

  enfoldrebuild = pkgs.writeShellScriptBin "enfoldrebuild" ''
    cd $HOME/projects/enfold/nixos
    fqdn="enfold.repoze.org"
    nixos-rebuild-ng switch --flake ".#''${fqdn%%.*}" \
      --target-host chrism@$fqdn --ask-sudo-password
  '';

  keithtemps = pkgs.writeShellScriptBin "keithtemps" ''
    sudo ${pkgs.ipmitool}/bin/ipmitool sdr type temperature
  '';

  whoosh = pkgs.writeShellScriptBin "whoosh" ''
    sudo systemctl stop idracfanctl.service && \
    sleep 30 && \
    sudo systemctl start idracfanctl.service
  '';

  nvfantemps = pkgs.writeShellScriptBin "nvfantemps" ''
    nvidia-smi --query-gpu=timestamp,utilization.gpu,fan.speed,temperature.gpu \
      --format=csv -l 10
  '';

  nixfmt80 = pkgs.writeShellScriptBin "nixfmt80" ''
    ${pkgs.nixfmt-rfc-style}/bin/nixfmt -w80 $@
  '';

  ffmpeg = "${pkgs.ffmpeg-full}/bin/ffmpeg";

  yt-transcode = pkgs.writeShellScriptBin "yt-transcode" ''
    ffmpeg -i "$1" -c:v h264_nvenc -preset slow -cq 23 -c:a aac -b:a 192k \
      -movflags +faststart output.mp4
  '';

  thumbnail = pkgs.writeShellScript "thumbnail" ''
    # writes to ./thumbnail.png
    # thumbnail eyedrops2.mp4 00:01:07
    ${ffmpeg} -y -i "$1" -ss "$2" \
      -vframes 1 thumbnail.png > /dev/null 2>&1
  '';

  extractmonopcm = pkgs.writeShellScript "extractmonopcm" ''
    ${ffmpeg} -i "$1" -map 0:a:0 -ac 1 -f s16le -acodec pcm_s16le "$2"
  '';

  yt-1080p = pkgs.writeShellScript "yt-1080p" ''
    # assumes 4k input
    ${ffmpeg} -i "$1" -c:v h264_nvenc -rc:v vbr -b:v 10M \
       -vf "scale=1920:1080" -r 30 -c:a aac -b:a 128k -movflags +faststart "$2"
  '';

  edit = pkgs.writeShellScriptBin "edit" ''
    if [[ "$XDG_SESSION_TYPE" == "tty" ]]; then
      exec emacsclient -c $@
    else
      exec emacsclient -n -c $@
    fi
  '';

  sessionVariables = { };

  zshDotDir =  config.users.users."chrism".home  + "/.config/zsh";

  shellAliases = {
    fxdevenv = ''
      export FXDEV_CHDIR=\"$(pwd)\"; \
      cd ~/projects/fornax/fxdevenv; \
      devenv shell;
    '';
    ragenv = ''
      cd ~/projects/enfold/afsoc-rag && devenv shell
    '';
    swnix = "sudo nixos-rebuild switch --verbose --show-trace";
    nhswnix = "${pkgs.nh}/bin/nh os switch /etc/nixos -- --show-trace";
    oldreplnix = "nix repl '<nixpkgs>'";
    replnix = "${pkgs.nh}/bin/nh os repl /etc/nixos";
    rbnix = "sudo nixos-rebuild build --rollback";
    mountzfs = "sudo zfs load-key d/o; sudo zfs mount d/o";
    restartemacs = "systemctl --user restart emacs";
    kbrestart = "systemctl --user restart keybase";
    toconsole = "sudo systemctl isolate multi-user.target";
    togui = "sudo systemctl isolate graphical.target";
    #ks = "loginctl terminate-session $XDG_SESSION_ID";
    open = "kioclient exec";
    sgrep = "rg -M 200 --hidden"; # dont display lines > 200 chars long
    ls = "ls --color=auto";
    ai = "shell-genie ask";
    diff = "${pkgs.colordiff}/bin/colordiff";
    disable-kvm = "sudo modprobe -r kvm-intel"; # for virtualbox
    thumbnail = "${thumbnail}";
    yt-1080p = "${yt-1080p}";
    extractmonopcm = "${extractmonopcm}";
    cullimgs = ''docker rmi $(docker images --filter "dangling=true" -q)'';
    nix-generations = ''
      sudo nix-env -p /nix/var/nix/profiles/system --list-generations
    '';
    dadsupdate = ''ssh -t enfold.repoze.org "sudo systemctl restart dads; journalctl -f -u dads.service"'';
    ragupdate = ''ssh -t enfold.repoze.org "sudo systemctl restart rag; journalctl -f -u rag.service"'';
  };

  graphicalimports =
    lib.optionals config.jawns.isworkstation [ ./graphical.nix ];

  # using emacs-pgtk for wayland
  emacswithpackages=(pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (
      epkgs: [
        epkgs.dockerfile-mode
        epkgs.nix-mode
        epkgs.nixpkgs-fmt
        epkgs.flycheck
        epkgs.json-mode
        epkgs.python-mode
        epkgs.auto-complete
        epkgs.web-mode
        epkgs.smart-tabs-mode
        epkgs.whitespace-cleanup-mode
        epkgs.flycheck-pyflakes
        epkgs.flycheck-pos-tip
        epkgs.nord-theme
        epkgs.nordless-theme
        epkgs.vscode-dark-plus-theme
        epkgs.doom-modeline
        epkgs.all-the-icons
        epkgs.all-the-icons-dired
        epkgs.magit
        epkgs.markdown-mode
        epkgs.markdown-preview-mode
        epkgs.gptel
        pkgs.emacs-all-the-icons-fonts
        epkgs.yaml-mode
        epkgs.multiple-cursors
        epkgs.dts-mode
        epkgs.rust-mode
        epkgs.nickel-mode
        epkgs.editorconfig
        epkgs.terraform-mode
        epkgs.lspce
        epkgs.lsp-mode
        epkgs.lsp-ui
        epkgs.lsp-jedi
        epkgs.company
        epkgs.dart-mode
        epkgs.adoc-mode
        epkgs.typescript-mode
        epkgs.tsc # maybe required for typescript-mode
      ]
  );

in

{
  # not good enough to just add ../home.nix to imports, must eagerly import,
  # or config.jawns can't be found
  imports = [ (import ../home.nix args) ] ++ graphicalimports;

  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    fd # fd is an unnamed dependency of fzf
    shell-genie
    nixpkgs-fmt # unnamed dependency of emacs package
    nixfmt80
    keithtemps
    whoosh
    nvfantemps
    yt-transcode
    edit
    typescript # for tsc for emacs
    remoterebuild
    enfoldrebuild
  ];

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = false;
  };

  xdg.configFile."black".text = ''
    [tool.black]
    line-length = 80
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # useful for the following matchBlocks."*"
    matchBlocks."*" = {
      forwardAgent = false;
      addKeysToAgent = "yes";
      compression = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      hashKnownHosts = false;
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };
    matchBlocks = {
      "192.168.1.*".forwardAgent = true;
      "quisling.local".forwardAgent = true;
      "quisling".forwardAgent = true;
      "lock802".forwardAgent = true;
      "clonelock802".forwardAgent = true;
      "keithmoon".forwardAgent = true;
      "optinix.".forwardAgent = true;
      "arctor.repoze.org".forwardAgent = true;
      "enfold.repoze.org".forwardAgent = true;
      "thinknix*".forwardAgent = true;
      "nixcentre".forwardAgent = true;
      "bouncer.repoze.org".forwardAgent = true;
      "lock802.repoze.org".forwardAgent = true;
      "optinix".forwardAgent = true;
      "win10".user = "user";
      "enfold-mac-studio.repoze.org".port = 19911;
      "enfold-mac-studio.repoze.org".forwardAgent = true;
      "biggysmalls".forwardAgent = true;
      "biggysmalls".user = "ec2-user";
      "smallysmalls".forwardAgent = true;
      "smallysmalls".user = "ec2-user";
      "demo.toughserv.com".forwardAgent = true;
      "apex.firewall" = {
        hostname = "apex.firewall";
        proxyJump = "bouncer.palladion.com";
        forwardAgent = true;
        serverAliveInterval = 60;
        localForwards = [
          # windresource
          {
            bind.port = 56526;
            host.port = 56526;
            host.address = "apex-gis.ace.apexcleanenergy.com";
          }
          # 8760, techdash, gisproject
          {
            bind.port = 1433;
            host.port = 1433;
            host.address = "ace-ra-sql1.ace.apexcleanenergy.com";
          }
          # mongo
          {
            bind.port = 27017;
            host.port = 27017;
            host.address = "ace-web-test.ace.apexcleanenergy.com";
          }
        ];
      };
      "15.200.113.205" = {
        user = "ec2-user";
        identityFile = "~/.ssh/id_ecdsa_enfold";
        forwardAgent = true;
        extraOptions = {
          HostKeyAlgorithms = "+ecdsa-sha2-nistp256";
          PubkeyAcceptedAlgorithms = "+ecdsa-sha2-nistp521";
          StrictHostKeyChecking = "no";
          AddKeysToAgent = "yes";
        };
      };
    };
  };

  # bare emacs
  programs.emacs.enable = true;
  programs.emacs.package = emacswithpackages;

  # emacsclient
  services.emacs.enable = true;
  services.emacs.package = emacswithpackages;

  home.file.".emacs.d" = {
    source = ./.emacs.d;
    recursive = true;
  };

  home.file.".p10k.zsh" = {
    source = ./.p10k-fornax.zsh;
    executable = true;
  };

  home.file.".p10k-theme.zsh" = {
    source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    executable = true;
  };

  programs.gitui.enable = true;

  programs.dircolors.enable = true;

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  programs.bash = {
    enable = true;
    shellAliases = shellAliases;
    sessionVariables = sessionVariables;
    enableCompletion = true;
  };

  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;
    sessionVariables = sessionVariables;
    enableCompletion = true;

    dotDir = zshDotDir; #config.home.homeDirectory + "/ " + zshDotDir;
    autosuggestion.enable = true;

    # speed up zsh start time, see
    # https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
    # (needs extended_glob)
    completionInit = ''
      # On slow systems, checking the cached .zcompdump file to see if it must
      # be regenerated adds a noticable delay to zsh startup.  This little
      # hack restricts it to once a day.  It should be pasted into your own
      # completion file.
      #
      # The globbing is a little complicated here:
      # - '#q' is an explicit glob qualifier that makes globbing work within
      #   zsh's [[ ]] construct.
      # - 'N' makes the glob pattern evaluate to nothing when it doesn't match
      #   (rather than throw a globbing error)
      # - '.' matches "regular files"
      # - 'mh+24' matches files (or directories or whatever) that are older
      #   than 24 hours.
      setopt extended_glob
      autoload -Uz compinit
      export ZDOTDIR=${zshDotDir}
      if [[ -n ${zshDotDir}/.zcompdump(#qN.mh+24) ]]; then
        compinit -u;
      else
        compinit -u -C;
      fi;
    '';

    #initExtraFirst = ''
    #  zmodload zsh/zprof
    #'';

    initContent = ''
      # be more bashy
      setopt interactive_comments bashautolist nobeep nomenucomplete \
             noautolist extended_glob

      source ~/.p10k.zsh
      source ~/.p10k-theme.zsh

      ## Keybindings section
      bindkey -e
      bindkey '^I' fzf-completion                         # anything**<TAB>
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

      findup () {
        # uses zsh extended globbing, https://unix.stackexchange.com/a/64164
        echo (../)#$1(:a)
      }

      ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin
      # authtoken_file=/run/agenix/enfold-cachix-authtoken
      # if [ -f $authtoken_file ]; then
      #    export CACHIX_AUTH_TOKEN="$(cat "$authtoken_file"|xargs)"
      # fi
      #zprof

      ulimit -n 65536
    '';
    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
    ];
  };

  # add this to ~/.gitconfig if this doesn't work
  # [credential]
  #   helper =
  #   helper = /nix/store/m0mgy49ffnkdmqfrjx3z5s6dk66prq8q-git-credential-manager-2.6.1/bin/git-credential-manager
  # [credential "https://dev.azure.com"]
  #   useHttpPath = true
  # [include]
  #   path = /home/chrism/.config/git/config

  programs.git = {
    enable = true;
    settings = {
      user.name = "Chris McDonough";
      user.email = "chrism@plope.com";
      pull.rebase = "true";
      # diff.guitool = "meld";
      # difftool.meld.path = "${pkgs.meld}/bin/meld";
      # difftool.prompt = "false";
      # merge.tool = "meld";
      # mergetool.meld.path = "${pkgs.meld}/bin/meld";
      safe.directory = [ "/etc/nixos" ];
      credential.helper = 
        "${pkgs.git-credential-manager}/bin/git-credential-manager";
      "credential \"https://dev.azure.com\"".useHttpPath = "true";
    };
  };

}
