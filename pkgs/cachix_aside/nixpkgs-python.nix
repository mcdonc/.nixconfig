{
  nix = {
    settings.substituters = [
      "https://nixpkgs-python.cachix.org"
    ];
    settings.trusted-public-keys = [
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
  };
}
