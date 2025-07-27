{ ... }:

{
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

}
