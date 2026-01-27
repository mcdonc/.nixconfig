{
  lib,
  config,
  pkgs,
  ...
}@args:

{
  home-manager = {
    # requires args
    users.chrism = (import ./home.nix args);
  };

  age.secrets."mcdonc-ubuntu-pro-attach" = {
    file = ../../secrets/mcdonc-ubuntu-pro-attach.age;
    mode = "600";
    owner = "chrism";
    group = "users";
  };

  age.secrets."enfold-alan-pat" = {
    file = ../../secrets/enfold-alan-pat.age;
    mode = "600";
    owner = "chrism";
    group = "users";
  };

  age.secrets."enfold-cachix-authtoken" = {
    file = ../../secrets/enfold-cachix-authtoken.age;
    mode = "600";
    owner = "chrism";
    group = "users";
  };
    

  # to make available in /run/agenix/foo
  environment.variables = {
    UBUNTU_PRO_ATTACH = config.age.secrets."mcdonc-ubuntu-pro-attach".path;
    ENFOLD_ALAN_PAT = config.age.secrets."enfold-alan-pat".path;
    CACHIX_AUTHTOKEN = config.age.secrets."enfold-cachix-authtoken".path;
  };

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
      "vboxusers" # for virtualbox
    ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDEWQSmS/BXw7/KXJRaS73VkNxA9K3Qt0+t+onQwznA cpmcdono"
        "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBADcMqSdxNPP26Ra83L3eyTz/BR+CCZh74vEyMUQlvXxSc9kLA+Qwjk+pf9FSlRSP4db/6OVospNPh2pFKgqeyYzZgG3m7aIwUo4RyxbS7wn+kpuQsA+TMfZArygowQzDFwnpqOkcvlj97pLbTfgghDxrCrn1VMF7pseJACebrZFffncHg== enfold ecdsa"
      ];
    };
  };
}
