{ ... }:
{
  # see https://github.com/NixOS/nixpkgs/issues/240383
  nixpkgs.overlays = [(self: super: {
    logcheck = super.logcheck.overrideAttrs (old: {
      postInstall = "rm -r $out/etc/logcheck/logcheck.logfiles.d";
    });
  })];

  services.logcheck.enable = true;

}
