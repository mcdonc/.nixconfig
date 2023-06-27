{ lib, stdenv, fetchFromGitHub, cmake, obs-studio, opencv, callPackage
, cudaPackages_11_6, autoPatchelfHook }:

let onnxruntime = callPackage ./onnxruntime.nix { tensorrtSupport = true; };
in stdenv.mkDerivation rec {
  pname = "obs-backgroundremoval";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "royshil";
    repo = "obs-backgroundremoval";
    rev = "v${version}";
    hash = "sha256-B8FvTq+ucidefIN3aqAJbezcHnTv6vYPxjYETiMiMFs"; #"sha256-Bq0Lfn+e9A1P7ZubA65nWksFZAeu5C8NvT36dG5N2Ug=";
  };

  nativeBuildInputs = [ cmake autoPatchelfHook ];
  buildInputs = [
    obs-studio
    onnxruntime
    opencv
#    cudaPackages_11_6.tensorrt_8_5_1
  ];

  dontWrapQtApps = true;

  cmakeFlags = [ "-DUSE_SYSTEM_ONNXRUNTIME=ON"
                 "-DUSE_SYSTEM_OPENCV=ON"
                 "-DOnnxruntime_INCLUDE_DIR=${onnxruntime.dev}/include/onnxruntime/core/providers/tensorrt"
#                 "-DCMAKE_VERBOSE_MAKEFILE=ON" # debugging
               ];

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
