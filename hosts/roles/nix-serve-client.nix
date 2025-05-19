{ ... }:
{
  nix.settings.substituters = [ "http://keithmoon:5000" ];
  nix.settings.trusted-substituters = [ "http://keithmoon:5000" ];
  nix.settings.trusted-public-keys = [ "nix-store-keithmoon:wnd5de8H4LDppfiIvh3b+BoPlJh+jVprtx/71gffJck=" ];
}
