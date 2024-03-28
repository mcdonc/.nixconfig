{}:
self: super: {
  # prevent openssh from checking perms of ~/.ssh/config to appease
  # vscode https://github.com/nix-community/home-manager/issues/322
  openssh = super.openssh.overrideAttrs (old: {
    patches = (
      old.patches or [ ]) ++ [
        ../patches/openssh-dontcheckconfigperms.patch ];
    doCheck = false;
  });
}
      
