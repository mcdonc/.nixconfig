{ config, pkgs, home-manager, ... }:

let
  restrictbackup = pkgs.stdenv.mkDerivation {
    name = "restrictbackup";
    dontUnpack = true;
    installPhase = "install -Dm755 ${./restrictbackup.py} $out/bin/restrictbackup";
    buildInputs = [ pkgs.python311 ];
  };

  restrictbackup2 = pkgs.writeShellScriptBin "restrictbackup" ''
    if [[ $SSH_ORIGINAL_COMMAND == "exit" ]]; then
       exit
    fi

    echo "$SSH_ORIGINAL_COMMAND" >> /tmp/commands

    exec $SSH_ORIGINAL_COMMAND

    declare -a arr=("echo" "command" "zpool" "zfs")

    for a in "''${arr[@]}"
    do
       if [[ $SSH_ORIGINAL_COMMAND == "$a"* ]] ; then
          exec $SSH_ORIGINAL_COMMAND
       fi
    done

    echo "Access denied to $SSH_ORIGINAL_COMMAND"
  '';

 
in {
  # Define a user account.
  users.users.backup = {
    isNormalUser = true;
    createHome = false;
    home = "/var/empty";
    extraGroups = [ ];
    openssh = {
      authorizedKeys.keys = [
        ''command="${restrictbackup2}/bin/restrictbackup" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
      ];
    };
  };

  services.sanoid = {
    enable = true;
    interval = "*:0/5";
    #interval = "hourly"; # run this hourly, run syncoid daily to prune ok
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

}
