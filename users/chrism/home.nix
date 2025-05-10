{ pkgs, lib, ... }:

let
  homedir = "/home/chrism";
  root-code-workspace = "${homedir}/.root.code-workspace";
  code-client = pkgs.writeShellScript "code-client" ''
    ${pkgs.procps}/bin/pgrep -x "code" > /dev/null
    if [ $? -eq 1 ];
    then
        ${pkgs.vscode-fhs}/bin/code ${root-code-workspace}
    fi
    exec ${pkgs.vscode-fhs}/bin/code -r $@
  '';

  shellAliases = {
    code-client = "${code-client}";
    vmbuild = "/etc/nixos/videos/composition/nixos/.vms/vmbuild.sh";
    vmrun = "/etc/nixos/videos/composition/nixos/.vms/vmrun.sh";
  };

in

{
  imports = [ ../home.nix ];

  home.stateVersion = "22.05";

  programs.zsh = {
    shellAliases = shellAliases;
    sessionVariables = {
      FXDEV_LOG_DEPLOYS="1";
   };
  };

  programs.bash = {
    shellAliases = shellAliases;
  };

  home.file.".root.code-workspace" = {
    source = ./root.code-workspace;
  };

  home.file.".root.code-workspace".force = true;

  programs.git = {
    enable = true;
    userName = "Chris McDonough";
    userEmail = "chrism@plope.com";
    extraConfig = {
      pull.rebase = "true";
      diff.guitool = "meld";
      difftool.meld.path = "${pkgs.meld}/bin/meld";
      difftool.prompt = "false";
      merge.tool = "meld";
      mergetool.meld.path = "${pkgs.meld}/bin/meld";
      safe.directory = [ "/etc/nixos" ];
    };
  };

  # https://dev.to/therubberduckiee/how-to-configure-starship-to-look-exactly-like-p10k-zsh-warp-h9h
  programs.starship = {
    enable = false;
    settings = {
      add_newline = false;
      command_timeout = 5000;
      format = ''
        [](bg:#1C2023 fg:#7DF9AA)\\
        [ ](bg:#7DF9AA fg:#090c0c)\\
        [](fg:#7DF9AA bg:#3B76F0)\\
        $directory\\
        [](fg:#3B76F0 bg:#FCF392)\\
        $git_branch\\
        $git_status\\
        $git_metrics\\
        [](fg:#FCF392 bg:#1C2023)\\

        $character'';
      directory = {
        truncation_length = 4;
        truncate_to_repo = false;
        truncation_symbol = "…/";
        format = "[ $path ]($style)";
        style = "fg:#E4E4E4 bg:#3B76F0";
      };
      git_branch = {
        format = "[ $symbol$branch(:$remote_branch) ]($style)";
        symbol = "  ";
        style = "fg:#1C3A5E bg:#FCF392";
      };
      git_status = {
        format = "[$all_status]($style)";
        style = "fg:#1C3A5E bg:#FCF392";
      };
      git_metrics = {
        format = "([+$added]($added_style))[]($added_style)";
        added_style = "fg:#1C3A5E bg:#FCF392";
        deleted_style = "fg:bright-red bg:235";
        disabled = false;
      };
      cmd_duration = {
        format = "[  $duration ]($style)";
        style = "fg:bright-white bg:18";
      };
      character = {
        #success_symbol = "[ ➜](bold green) ";
        success_symbol = "[>](bold green)";
        error_symbol = "[✗](#E84D44)";
      };
      time = {
        disabled = true;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:#1d2230";
        format = "[[ 󱑍 $time ](bg:#1C3A5E fg:#8DFBD2)]($style)";
      };
    };
  };

  # systemctl --user status nix-index.service
  # systemd.user.services.nix-index = {
  #   Unit = {
  #     Description = "Run nix-index.";
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.nix-index}/bin/nix-index";
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

  # # systemctl --user status nix-index.timer
  # systemd.user.timers.nix-index = {
  #   Unit = {
  #     Description = "Timer for nix-index.";
  #   };
  #   Timer = {
  #     Unit = "nix-index.service";
  #     #OnCalendar = "*:0/5";
  #     OnCalendar = "*-*-* 10:00:00";
  #   };
  #   Install = {
  #     WantedBy = [ "timers.target" ];
  #   };
  # };

  # systemd.user.services.watchintake = {
  #   Unit = {
  #     Description = "Run watchintake.";
  #   };
  #   Service = {
  #     ExecStart = ''
  #       ${watchintake}/bin/watchintake ${homedir}/intake
  #     '';
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

}
