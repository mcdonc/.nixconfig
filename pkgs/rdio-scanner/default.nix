{ pkgs, ...}:

let
  version = "6.6.3";
  rdio-scanner-src = pkgs.fetchFromGitHub {
    owner = "chuot";
    repo = "rdio-scanner";
    rev = "v${version}";
    sha256 = "sha256-Icy5DQtjbpejyUCPGGTc5X+zrMccmUk9C7FNaG0H42U=";
  };
  rdio-scanner-client = pkgs.buildNpmPackage {
    pname = "rdio-scanner-client";
    inherit version;
    src = rdio-scanner-src;
    patches = [ ./angular-outpath.patch ];
    sourceRoot = "${rdio-scanner-src.name}/client";
    npmDepsHash = "sha256-BmW4MUWhZflzBhsBqI2X52dtMtCVm+LgzTI7J8/B3OU=";
    postInstall = ''
      mkdir -p $out
      cp -r /build/webapp $out
    '';
  };
  rdio-scanner-server = pkgs.buildGoModule {
    pname = "rdio-scanner-server";
    inherit version;
    src = rdio-scanner-src;
    sourceRoot = "${rdio-scanner-src.name}/server";
    vendorHash = "sha256-Dvb8g+XtMcI9bbB83AZ94UI54L10jmBnXYrgzGe9200=";
    postUnpack = ''
      cp -r ${rdio-scanner-client}/webapp /build/source/server
    '';
    postInstall = ''
      mv $out/bin/server $out/bin/rdio-scanner
    '';
    meta = with pkgs.lib; {
      description = "The perfect software-defined radio companion.";
      longDescription = ''
        Open source software that ingests and distributes audio files 
        generated by various software-defined radio recorders. Its
        interface tries to reproduce the user experience of a real
        police scanner.
        '';
      homepage = "https://github.com/chuot/rdio-scanner";
      license = licenses.gpl3Plus;
      maintainers = with maintainers; [ ];
      platforms = platforms.linux;
      mainProgram = "rdio-scanner";
    };
  };
in
{
  environment.systemPackages = [
    rdio-scanner-server
  ];
}
