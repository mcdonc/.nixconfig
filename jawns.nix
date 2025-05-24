# locally-used options for my jawns
{ lib, ... }:
{
  options.jawns = {
    isworkstation = lib.mkOption {
      type = lib.types.bool;
      description = "Is this build for a workstation?";
      default = lib.mkDefault false;
    };
  };
}
