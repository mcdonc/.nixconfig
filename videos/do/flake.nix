{
  description = "Digital Ocean Demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosConfigurations = {
      dodemo = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = inputs;
        system = "x86_64-linux";
        modules = [ ./dodemo.nix ];
      };
    };
  };
}
