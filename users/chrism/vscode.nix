args@{ pkgs, lib, ... }:

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
  };

in

{
  programs.zsh = {
    shellAliases = shellAliases;
  };

  home.file.".root.code-workspace" = {
    source = ./root.code-workspace;
  };

  home.file.".root.code-workspace".force = true;

}
