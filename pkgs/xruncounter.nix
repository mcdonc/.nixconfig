{ pkgs, ...}:

pkgs.stdenv.mkDerivation {
  name = "xruncounter";
  src = pkgs.fetchFromGitHub {
    owner = "Gimmeapill";
    repo = "xruncounter";
    rev = "4c234dd";
    sha256 = "sha256-ShhkJ0GzXsJ8ZfhvVkASHeFZ5V2a/0KPj0zXpE9D/JU=";
  };
  buildInputs = [
    pkgs.libjack2
  ];
  buildPhase = ''
    gcc -Wall xruncounter.c -ljack -o xruncounter
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp xruncounter $out/bin
  '';
}
