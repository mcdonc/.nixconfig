{
  lib,
  config,
  pkgs,
  ...
}:

{
  # Define a user account.
  users.users.alan = {
    isNormalUser = true;
    shell = pkgs.bash;
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
      "vboxusers" # for virtualbox
    ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOvQSBJUaI8r2koqX1RJAq2+z/3ia2C5b+6q3iTMS9n",
      ];
    };
  };
}
