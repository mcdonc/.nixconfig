with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "bool";
  src = ./bool.tar.gz;
  preBuild = ''
    export PREFIX=$out
    export NIX_DEBUG=1
  '';
  buildInputs = [ boolector ];
}
