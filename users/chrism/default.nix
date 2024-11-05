{ lib, config, pkgs, ... }:

let
  intake = "/home/chrism/intake";
  intake-events = "IN_CLOSE_WRITE,IN_MOVED_TO";
in
{
  home-manager = {
    users.chrism = import ./home.nix;
  };

  nix.settings.trusted-users = [ "chrism" ];
  
  # Define a user account.
  users.users.chrism = {
    isNormalUser = true;
    initialPassword = "pw321";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "docker"
      "nixconfig"
      "dialout"
      "wireshark"
      "vboxusers"
      "libvirtd"
      "kvm"
      "input"
      "postgres"
      "plugdev" # for rtl-sdr
    ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDEWQSmS/BXw7/KXJRaS73VkNxA9K3Qt0+t+onQwznA cpmcdono"
      ];
    };
  };
  # inotifywait -mr -e close_write -e moved_to -e moved_from -e delete .

  # # https://manpages.debian.org/testing/incron/incrontab.5.en.html
  # # IN_CREATE,IN_MODIFY,IN_CLOSE_WRITE,IN_MOVED_FROM,IN_MOVED_TO
  # # IN_ALL_EVENTS,dotdirs=true
  # # segfault issue: https://github.com/ar-/incron/issues/11
  # services.incron.enable = true;
  # services.incron.extraPackages = [ pkgs.coreutils pkgs.incron ];
  # systemd.services.incron.serviceConfig.Restart = lib.mkForce "always";
  # system.activationScripts.incron-chrism = ''
  #   mkdir -p ${intake}
  #   chown chrism:users ${intake}
  #   echo "setting up incrontab"
  #   tmpfile=$(mktemp)
  #   #echo '${intake} ${intake-events} echo "$@ $# $%" >> /home/chrism/incron.log' > $tmpfile
  #   echo '${intake} ${intake-events} echo "$# $%" >> /home/chrism/incron.log' > $tmpfile
  #   ${pkgs.incron}/bin/incrontab -u chrism -r
  #   ${pkgs.incron}/bin/incrontab -u chrism $tmpfile
  #   ${pkgs.incron}/bin/incrontab -u chrism -d
  #   rm -f $tmpfile
  # '';
}
