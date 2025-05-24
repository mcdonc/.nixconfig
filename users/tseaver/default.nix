{ lib, config, pkgs, ... }:

{
  nix.settings.trusted-users = [ "tseaver" ];

  # Define a user account.
  users.users.tseaver = {
    isNormalUser = true;
    shell = pkgs.bash;
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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD2mTsHXU4IBdPQrmuRBeJr4qSjV4XN5uwvBgRtzB6PRSO2b4GiYP15iY08i+LlNcGEAHqIdTYV8q0rrvQiQxvKzvrw8s2oizUDWMpAc6vQWA57dHGgZ3x98krPcNET7bWrD5PW5HrIS5RpGZOsc/op63PqwxE3Wjlq2Uhc4rzf7A6t375V15tEJvjGN0z0FnfX8dtusWNdlWoPqArRiciw610L0uO1YvNao3WNKcWATm2JgVVCsrvLxcwVboFLgpYaZtdqZ0Qsh5V1cfhL7O9HcxkfokgLILOigtDYZbQt7bWtxHeoYq4uErP5IS416e5gHmouhFK3B3Lo/CxI3LR"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQv9BpuAhaf9KHt3iNNI+vHRzCzSBW2778RW0A2h6OFkmkRVca2qAgY9+YwIFd4NKtcl8obWeR/3biUeTii+H4aCLUVHYyBs/+K/UzQuBgKeF2X9V/aDzElk+kc2S0uVh9aaU6rJpq20KL8OvQ6s7REVPg6cE3NH6C38V6SJ+91b4S1kpxIfSoG+ZBEuY79leOMAlIM9TR957bjysnK1CIexV3k6hLSeTT+Sz6z80wnsYX84o989x4dFiK8XqYp/X6nWsAR4P552ObyDiBBKZCrWh13NwGu73BVFas2GkB7mMPN6GQt75odqOzJNhOmJAadAWUgrKxJCwHI0Fn1XY/byHFVJOp3HiDLTr87+2tsVOA7nMABX/yBvfNh9/EALws8w70v90mlkQ34QMSdpSTIT5yrgPzzH8DR5DDvMofSUlod6jsYZKOHR1G80M6V0L8CZpSfYtEEfMs87ZMOXvq1T/Epfm8S1XGdsa43MDnKKuohzv428Rkd0uxR+6QDdk="
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9wBXRN8LimFia9KNhTEypd7q9GzHTYeC301e6y+QEoeNzf9//JuL23vUMUbSAPWW3aLfTQd29FFq1l3aEGNSpKkx1VKqRHWqHBC7HV0auU3RKy+bjKbCdhcIIiz7Exaa4MVyDWTCdSd+tHDpERKt7flhe2KZ8nb1JFBm8mjxtz/yO6RZmEXYCuUwRO1NlfS2mNzXDoY8crUxIUFuhUu5UHe2p3tGV7EGcqVVWGNvlpNk5qk+uUvmxs73xcYChfL7y/EwTp0FFuTRZpuxPv7fKR5ofjzannbnvl1Sz2db2ep6VH++6L7iu/Ehjwsl3rO9Or18N7XQYw9NOAxe/AvdhcFWMspI/rGvOi+Pq9Bq+2Gs4RoBCcFfVGqxFayvUWFioTD86jHeDXDXbAi4NKgtX3IeY+yBsvUyAg/8YRgEMkoMwMUWPP0lpMC04M4NpJ7uOEzFhl+kp42cpGl68TN1s177odhc9fNG9w25f4lgu234FsJNAX1Y/9QAijQkpfac="
      ];
    };
  };
}
