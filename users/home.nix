{
  pkgs,
  lib,
  config,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;

}
