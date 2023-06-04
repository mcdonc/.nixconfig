NixOS 41: Mixing Older and Newer nixpkgs Packages Under a Flakes-based Config
=============================================================================

- Companion to video at

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- NixOS 23.05 upgrades Olive video editor (https://www.olivevideoeditor.org/)
  to 0.2.  On 22.11, it was at 0.1.2.

- 0.2 is a very work-in-progress sort of thing (I am a patron).

- I'd like to stick with 0.1.2 until Matt makes an actual release of 0.2.

- There are quite a few good guides on how to do things like this in
  non-flakes-based configurations.  Not so much on flakes-based.

- But it's not too hard.  In my case, I know that the release in the previous
  NixOS (22.11) works fine, so I'll use that.

  We have to do some work in our ``flake.nix`` first.  Before this work, it
  looks like this::

   {
     description = "Chris' Jawns";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
       nixos-hardware.url = "github:NixOS/nixos-hardware";
       home-manager.url = "github:nix-community/home-manager/release-23.05";
     };

     outputs =
       { self, nixpkgs, nix, nixos-hardware, home-manager }: {
         nixosConfigurations = {
           thinknix512 = nixpkgs.lib.nixosSystem {
             system = "x86_64-linux";
             modules = [
               nixos-hardware.nixosModules.lenovo-thinkpad-p51
               ./hosts/thinknix512.nix
               ./users/chrism/user.nix
               home-manager.nixosModules.home-manager
               {
                 home-manager.useUserPackages = true;
                 home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
             ];
           };
    ...

  After our work, it looks like this::

     {
       description = "Chris' Jawns";

       inputs = {
         nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
         nixos-hardware.url = "github:NixOS/nixos-hardware";
         home-manager.url = "github:nix-community/home-manager/release-23.05";
         nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
       };

       outputs =
         { self, nixpkgs, nix, nixos-hardware, home-manager, nixpkgs-r2211 }:
         let
           system = "x86_64-linux";
           overlay-r2211 = final: prev: {
             r2211 = import nixpkgs-r2211 {
               inherit system;
               config.allowUnfree = true;
             };
           };
         in {
           nixosConfigurations = {
             thinknix512 = nixpkgs.lib.nixosSystem {
               inherit system;
               modules = [
                 ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
                 nixos-hardware.nixosModules.lenovo-thinkpad-p51
                 ./hosts/thinknix512.nix
                 ./users/chrism/user.nix
                 home-manager.nixosModules.home-manager
                 {
                   home-manager.useUserPackages = true;
                   home-manager.users.chrism = import ./users/chrism/hm.nix;
                 }
               ];
             };
     ...
    
- Using this "overlay-r2211" overlay allows us to refer to packages from the
  22.11 release as "pkgs.r2211.<packagename>"

- So, elsewhere in my config::

    environment.systemPackages = with pkgs; [
      ...
      r2211.olive-editor
      ...

- Replace the 22.11 release input with any other input as necessary.
  
