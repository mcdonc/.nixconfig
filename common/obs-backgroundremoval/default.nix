{ lib, stdenv, fetchFromGitHub, cmake, obs-studio, opencv, callPackage }:

let onnxruntime = callPackage ./onnxruntime { };
in stdenv.mkDerivation rec {
  pname = "obs-backgroundremoval-0_5_17";
  version = "0.5.17";

  src = fetchFromGitHub {
    owner = "royshil";
    repo = "obs-backgroundremoval";
    rev = "v${version}";
    hash = "";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ obs-studio onnxruntime opencv ];

  dontWrapQtApps = true;

  cmakeFlags = [ "-DUSE_SYSTEM_ONNXRUNTIME=ON" "-DUSE_SYSTEM_OPENCV=ON" ];

  postInstall = ''
    mkdir $out/lib $out/share
    mv $out/obs-plugins/64bit $out/lib/obs-plugins
    rm -rf $out/obs-plugins
    mv $out/data $out/share/obs
  '';

  meta = with lib; {
    description =
      "OBS plugin to replace the background in portrait images and video";
    homepage = "https://github.com/royshil/obs-backgroundremoval";
    maintainers = with maintainers; [ zahrun ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
