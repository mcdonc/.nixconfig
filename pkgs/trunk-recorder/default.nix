{ pkgs, ... }:

let
  trunk-recorder = pkgs.stdenv.mkDerivation rec {
    pname = "trunk-recorder";
    version = "4.7.1";
    src = pkgs.fetchFromGitHub {
      owner = "robotastic";
      repo = "trunk-recorder";
      rev = "v${version}";
      sha256 = "sha256-nL59+BAL5zKoAZs+i947Zzmj7U0UNsbmMCLnpTLaMQA=";
    };
    nativeBuildInputs = [
      pkgs.cmake
      pkgs.pkg-config
      pkgs.makeWrapper
    ];
    cmakeFlags = [
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
      "-DSPDLOG_FMT_EXTERNAL=ON"
    ];
    buildInputs = [
      pkgs.gnuradio
      pkgs.gnupg
      pkgs.libsndfile
      pkgs.fftw
      pkgs.cacert
      pkgs.gnuradioPackages.osmosdr
      pkgs.uhd
      pkgs.boost
      pkgs.curl
      pkgs.gmp
      pkgs.hackrf
      pkgs.orc
      pkgs.xorg.libpthreadstubs
      pkgs.openssl
      pkgs.libusb1
      pkgs.git
      pkgs.spdlog
      pkgs.volk
    ];
    postInstall = ''
      wrapProgram $out/bin/trunk-recorder \
       --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.sox pkgs.fdk-aac-encoder ]}
    '';
    meta = with pkgs.lib; {
      description = "Record calls on trunked and conventional radio systems.";
      homepage = "https://github.com/robotastic/trunk-recorder";
      license = licenses.gpl3Plus;
      maintainers = with maintainers; [ ];
      platforms = platforms.linux;
      mainProgram = "trunk-recorder";
    };
  };
in
{
  environment.systemPackages = [
    trunk-recorder
  ];
}
