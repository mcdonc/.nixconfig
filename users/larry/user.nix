{ config, pkgs, home-manager, ... }:

{
  # Define a user account.
  users.users.larry = {
    isNormalUser = true;
    initialPassword = "pw321";
    extraGroups =
      [
        "wheel"
        "networkmanager"
        "audio"
        "docker"
        "nixconfig"
        "dialout"
        "docker"
        "vboxusers"
        "libvirtd"
        "kvm"
        "input"
      ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPUUOSs6sqwBofcXAsX+D+1OpZiS+K59QbV87GWMcpQ larry@agendaless.com"
      ];
    };
  };

}
