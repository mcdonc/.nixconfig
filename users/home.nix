{ pkgs, lib, config, ... }:

let

  keithtemps = pkgs.writeShellScriptBin "keithtemps" ''
    sudo ${pkgs.ipmitool}/bin/ipmitool sdr type temperature
  '';

  whoosh = pkgs.writeShellScriptBin "whoosh" ''
    sudo systemctl stop idracfanctl.service && \
    sleep 30 && \
    sudo systemctl start idracfanctl.service
  '';

  nvfantemps = pkgs.writeShellScriptBin "nvfantemps" ''
    nvidia-smi --query-gpu=timestamp,utilization.gpu,fan.speed,temperature.gpu --format=csv -l 10
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

  sessionVariables = {};

  zshDotDir = ".config/zsh";

  shellAliases = {
    fxdevenv = ''
     export FXDEV_CHDIR=\"$(pwd)\"; \
     cd ~/projects/fornax/fxdevenv; \
     devenv shell";
    '';
    oldswnix = "sudo nixos-rebuild switch --verbose --show-trace";
    swnix = "${pkgs.nh}/bin/nh os switch /etc/nixos -- --show-trace";
    oldreplnix = "nix repl '<nixpkgs>'";
    replnix = "${pkgs.nh}/bin/nh os repl /etc/nixos";
    rbnix = "sudo nixos-rebuild build --rollback";
    mountzfs = "sudo zfs load-key d/o; sudo zfs mount d/o";
    restartemacs = "systemctl --user restart emacs";
    kbrestart = "systemctl --user restart keybase";
    toconsole = "sudo systemctl isolate multi-user.target";
    togui = "sudo systemctl isolate graphical.target";
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
  };

  graphicalimports = lib.optionals config.jawns.isworkstation
    [ ./graphical.nix ];

in

{
  imports = graphicalimports;

  nixpkgs.config.allowUnfree = true;

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
  ];

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  xdg.configFile."black".text = ''
    [tool.black]
    line-length = 80
  '';

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "192.168.1.*".forwardAgent = true;
      "lock802".forwardAgent = true;
      "clonelock802".forwardAgent = true;
      "keithmoon".forwardAgent = true;
      "optinix.".forwardAgent = true;
      "arctor.repoze.org".forwardAgent = true;
      "thinknix*".forwardAgent = true;
      "nixcentre".forwardAgent = true;
      "bouncer.repoze.org".forwardAgent = true;
      "lock802.repoze.org".forwardAgent = true;
      "optinix".forwardAgent = true;
      "win10" .user = "user";
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
    };
  };

  programs.emacs.enable = true;
  programs.emacs.extraPackages = epkgs: [
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
  ];

  services.emacs.enable = true;

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

    dotDir = zshDotDir;
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
      export ZDOTDIR=~/${zshDotDir}
      if [[ -n ~/${zshDotDir}/.zcompdump(#qN.mh+24) ]]; then
        compinit;
      else
        compinit -C;
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

      #zprof
    '';
    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
    ];
  };
}
