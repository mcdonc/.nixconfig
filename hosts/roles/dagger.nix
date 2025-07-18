{ pkgs, inputs, system, dagger, ... }:
# let
#   dagger = import inputs.dagger {
#     system = system;
#   };
# in
{
  environment.systemPackages = [
    dagger.packages.${system}.dagger
  ];
}
