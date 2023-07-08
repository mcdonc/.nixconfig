with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "bool";
  src = ./bool.tar.gz;
  preBuild = ''
    export PREFIX=$out
  '';
  buildInputs = [ boolector ];
}
