{ pkgs }:
let
  # there is no 2.11 tag
  version = "2.12";
  hello = pkgs.fetchFromGitHub {
    owner = "ritza-co";
    repo = "simple-hello-world-demo";
    rev = "v${version}";
    sha256 = "sha256-4GQeKLIxoWfYiOraJub5RsHNVQBr2H+3bfPP22PegdU=";
  };
in
pkgs.stdenv.mkDerivation  {
  pname = "hello";
  version = version;
  src = hello;
}
