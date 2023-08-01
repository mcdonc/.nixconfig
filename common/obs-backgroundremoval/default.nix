{ lib, stdenv, fetchFromGitHub, cmake, obs-studio, opencv, curl, ninja ,
libsForQt5, qt6, callPackage, cudaPackages_11_8, autoPatchelfHook,
addOpenGLRunpath }:

# obs startup

# Jul 13 14:16:18 thinknix512 kded5[8669]: Registering ":1.574/StatusNotifierItem" to system tray
# Jul 13 14:17:52 thinknix512 kded5[8669]: Registering ":1.577/StatusNotifierItem" to system tray
# Jul 13 14:17:52 thinknix512 kernel: [drm:nv_drm_fence_context_create_ioctl [nvidia_drm]] *ERROR* [nvidia-drm] [GPU ID 0x00000100] Failed to allocate fence signaling event

# obs shutdown

# Jul 13 14:19:10 thinknix512 kded5[8669]: Service  ":1.574" unregistered
# Jul 13 14:19:10 thinknix512 kernel: tiny_tubular_ta[353724]: segfault at 7f77b03eaa60 ip 00007f77b03eaa60 sp 00007f77fd0e3c28 error 14 likely on CPU 2 (core 2, socket 0)
# Jul 13 14:19:10 thinknix512 kernel: Code: Unable to access opcode bytes at 0x7f77b03eaa36.
# Jul 13 14:19:10 thinknix512 systemd[1]: Started Process Core Dump (PID 355109/UID 0).
# Jul 13 14:19:21 thinknix512 systemd-coredump[355110]: [🡕] Process 353717 (.obs-wrapped) of user 1000 dumped core.

#     Module libonnxruntime_providers_cuda.so without build-id.
#     Module libonnxruntime_providers_shared.so without build-id.
#     Module libquadmath.so.0 without build-id.
#     Module libgfortran.so.5 without build-id.
#     Module libopenblas.so.0 without build-id.
#     Module libopencv_core.so.407 without build-id.
#     Module libopencv_imgproc.so.407 without build-id.
#     Module libonnxruntime.so.1.14.1 without build-id.
#    Module obs-backgroundremoval.so without build-id.
#     .. elided ..
#     Module .obs-wrapped without build-id.
#     Stack trace of thread 353724:
#     #0  0x00007f77b03eaa60 n/a (n/a + 0x0)
#     ELF object binary architecture: AMD x86-64
# Jul 13 14:19:21 thinknix512 systemd[1]: systemd-coredump@246-355109-0.service: Deactivated successfully.
# Jul 13 14:19:21 thinknix512 systemd[1]: systemd-coredump@246-355109-0.service: Consumed 10.138s CPU time, no IP traffic.
# Jul 13 14:19:21 thinknix512 kded5[8669]: Service  ":1.577" unregistered
# Jul 13 14:19:21 thinknix512 kwin_x11[8671]: kwin_core: Failed to focus 0x5000008 (error 3)
# Jul 13 14:19:21 thinknix512 kwin_x11[8671]: kwin_core: XCB error: 152 (BadDamage), sequence: 54145, resource id: 23530895, major code: 143 (DAMAGE), minor code: 3 (Subtract)

let onnxruntime = callPackage ./onnxruntime.nix { };
in stdenv.mkDerivation rec {
  pname = "obs-backgroundremoval";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "royshil";
    repo = "obs-backgroundremoval";
    rev = "v${version}";
    hash = "sha256-bBx0CnbmAQ8WKG017sab1d8Js6+MfiQj1y+FLgEaaLU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs =
    [ cmake cudaPackages_11_8.autoAddOpenGLRunpathHook autoPatchelfHook
      ninja ];

  buildInputs =
    [ obs-studio onnxruntime opencv qt6.qtbase curl ];

  dontWrapQtApps = true;

  env.NIX_CFLAGS_COMPILE = ''
    -I${onnxruntime.dev}/include/onnxruntime/core/providers/tensorrt
    -L${onnxruntime}/lib
    -Wl,--no-undefined
  '';

  # pulled from scripts/PKGBUILD
  cmakeFlags = [
    "-DENABLE_QT=ON"
    "-DENABLE_FRONTEND_API=ON"
    "-DCMAKE_MODULE_PATH=${src}/cmake"
    "-DobsIncludePath=${obs-studio}/include/obs"
    "-DVERSION={$version}"
    "-DUSE_SYSTEM_ONNXRUNTIME=ON"
    "-DUSE_SYSTEM_OPENCV=ON"
    "-DUSE_SYSTEM_CURL=ON"
    "-DOnnxruntime_INCLUDE_DIR=${onnxruntime.dev}/include"
    "-DOnnxruntime_LIBRARIES=${onnxruntime}/lib/libonnxruntime.so"
  ];

  passthru.obsWrapperArguments = [
    "--prefix LD_LIBRARY_PATH : ${onnxruntime}/lib"
    "--prefix LD_LIBRARY_PATH : ${addOpenGLRunpath.driverLink}/lib"
    "--prefix LD_LIBRARY_PATH : ${onnxruntime}/lib"
  ];

  meta = with lib; {
    description =
      "OBS plugin to replace the background in portrait images and video";
    homepage = "https://github.com/royshil/obs-backgroundremoval";
    maintainers = with maintainers; [ zahrun ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
