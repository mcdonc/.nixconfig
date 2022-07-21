{config, pkgs, ...}:

rec {
  oldpath = pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    # ardour 6.7
    rev = "e9e5f5f84dedea81605e493ea6cec41275a9a8fd";
    sha256 = "sha256-49ogeV9eO3RhEbVdrKCKBrbByGv9tU0AdBLCHDENzYY=";
  };
  oldpkgs = import "${oldpath}" {};
  oldardour = oldpkgs.ardour;
  
  # nixpkgs.overlays = [
  #   (self: super: {
  #     ardour-git = super.ardour.overrideAttrs (old: {
  #       src = super.fetchgit {
  #         url = "git://git.ardour.org/ardour/ardour.git";
  #         # 6.8
  #         rev = "1734fac4105106e02219834d330fa9eb0ceef3cd";
  #         #sha256 = "0000000000000000000000000000000000000000000000000000";
  #         sha256 = "sha256-msTTNIFkCUf5TljtFbhEQMrxhYMz74K5fxnMvP5cp5s=";
  #       };
  #     });
  #   })
  # ];

}



  
