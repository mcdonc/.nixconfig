{ ... }:
{
  nix.settings.substituters = [ "http://keithmoon:5000" ];
  nix.settings.trusted-substituters = [ "http://keithmoon:5000" ];
  nix.settings.trusted-public-keys = [ "nix-serve-keithmoon:ouITNUagrAyEVzSlnQXJewp5aQhAOu1PPnN5RcN8PJ0=" ];
}
