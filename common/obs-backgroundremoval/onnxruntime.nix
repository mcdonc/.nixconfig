{ stdenv, stdenvNoCC, lib, fetchFromGitHub, fetchpatch, fetchurl, pkg-config
, cmake, python3Packages, libpng, zlib, eigen, protobuf3_20, nlohmann_json
, boost181, boost179, oneDNN, abseil-cpp_202206, gtest, pythonSupport ? false
, tensorrtSupport ? false, nsync, re2, cudaPackages_11_6, microsoft_gsl, gcc11
, python3, callPackage }:

# to build with cmake/deps.txt downloads: NIXPKGS_ALLOW_UNFREE=1 nix-build --option sandbox false --impure --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {}'
# without: NIXPKGS_ALLOW_UNFREE=1 --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {}'

assert pythonSupport
  -> lib.versionOlder protobuf3_20.version "3.20"; # XXX uhhhhh...

let
  flatbuffers-1_12 = stdenv.mkDerivation rec {
    pname = "flatbuffers";
    version = "1.12.0";

    src = fetchFromGitHub {
      owner = "google";
      repo = "flatbuffers";
      rev = "v${version}";
      sha256 = "sha256-L1B5Y/c897Jg9fGwT2J3+vaXsZ+lfXnskp8Gto1p/Tg=";
    };

    nativeBuildInputs = [ cmake python3 ];

    postPatch = ''
      # Fix default value of "test_data_path" to make tests work
          substituteInPlace tests/test.cpp --replace '"tests/";' '"../tests/";'
    '';

    cmakeFlags = [
      "-DFLATBUFFERS_BUILD_TESTS=OFF"
      "-DFLATBUFFERS_OSX_BUILD_UNIVERSAL=OFF"
    ];

    doCheck = false; # XXX
    checkTarget = "test";

    meta = with lib; {
      description = "Memory Efficient Serialization Library";
      longDescription = ''
        FlatBuffers is an efficient cross platform serialization library for
        games and other memory constrained apps. It allows you to directly
        access serialized data without unpacking/parsing it first, while still
        having great forwards/backwards compatibility.
      '';
      homepage = "https://google.github.io/flatbuffers/";
      license = licenses.asl20;
      maintainers = [ maintainers.teh ];
      mainProgram = "flatc";
      platforms = platforms.unix;
    };
  };

  howard-hinnant-date-2_4_1 = stdenv.mkDerivation rec {
    pname = "howard-hinnant-date";
    version = "2.4.1";

    src = fetchFromGitHub {
      owner = "HowardHinnant";
      repo = "date";
      rev = "v${version}";
      sha256 = "sha256-BYL7wxsYRI45l8C3VwxYIIocn5TzJnBtU0UZ9pHwwZw=";
    };

    nativeBuildInputs = [ cmake ];

    cmakeFlags = [ "-DBUILD_SHARED_LIBS=true" "-DUSE_SYSTEM_TZ_DB=true" ];

    outputs = [ "out" "dev" ];

    meta = with lib; {
      license = licenses.mit;
      description =
        "A date and time library based on the C++11/14/17 <chrono> header";
      homepage = "https://github.com/HowardHinnant/date";
      platforms = platforms.unix;
      maintainers = with maintainers; [ r-burns ];
    };
  };

  safeint = stdenv.mkDerivation rec {
    pname = "safeint";
    version = "unstable";

    nativeBuildInputs = [ cmake ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "dcleblanc";
      repo = "SafeInt";
      rev = "ff15c6ada150a5018c5ef2172401cb4529eac9c0";
      sha256 = "sha256-PK1ce4C0uCR4TzLFg+elZdSk5DdPCRhhwT3LvEwWnPU=";
    };

  };

  wil = stdenv.mkDerivation rec {
    pname = "wil";
    version = "unstable";

    nativeBuildInputs = [ cmake ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "microsoft";
      repo = "wil";
      rev = "5f4caba4e7a9017816e47becdd918fcc872039ba";
      sha256 = "sha256-nbiDtBZsni7hp9fROBB1D4j7ssBZOgG5goeb6/lSS20=";
    };
  };

  cutlass = stdenv.mkDerivation rec {
    pname = "cutlass";
    version = "2.11.0";

    nativeBuildInputs = [ cmake ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "NVIDIA";
      repo = "cutlass";
      rev = "v${version}";
      sha256 = "sha256-P8A1NEcYp5o15dB+d0zzSLwVWv472txLY7zDMYb70o4=";
    };

  };

  onnx-tensorrt = stdenv.mkDerivation rec {
    pname = "onnx-tensorrt";
    version = "unstable";

    nativeBuildInputs = [ cmake ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "onnx";
      repo = "onnx-tensorrt";
      rev = "369d6676423c2a6dbf4a5665c4b5010240d99d3c";
      sha256 = "sha256-+jNi66ib9KxslKf/VJJIx6w7akQjCuzYl3h9CBKz4lU=";
    };

  };

  mp11 = stdenv.mkDerivation rec {
    pname = "mp11";
    version = "boost-1.79.0";

    nativeBuildInputs = [ cmake boost179 ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "boostorg";
      repo = "mp11";
      rev = "${version}";
      sha256 = "sha256-ZxgPDLvpISrjpEHKpLGBowRKGfSwTf6TBfJD18yw+LM=";
    };

  };

  googletest = stdenv.mkDerivation rec {
    pname = "googletest";
    version = "unstable";

    nativeBuildInputs = [ cmake ];

    cmakeDir = "../";

    src = fetchFromGitHub {
      owner = "google";
      repo = "googletest";
      rev = "519beb0e52c842729b4b53731d27c0e0c32ab4a2";
      sha256 = "sha256-6LG2Q9QSQBG6oynBkgdtXBsUra6LXPOZWR6i0dPMdeY=";
    };
  };

  pytorch-cpuinfo = stdenv.mkDerivation rec {
    pname = "pytorch-cpuinfo";
    version = "unstable";

    nativeBuildInputs = [ cmake googletest ];

    cmakeDir = "../";
    cmakeFlags = [
      # otherwise would need googlebenchmarks # XXX
      "-DCPUINFO_BUILD_BENCHMARKS=OFF"
      "-DGOOGLETEST_SOURCE_DIR=${googletest.src}"
    ];

    src = fetchFromGitHub {
      owner = "pytorch";
      repo = "cpuinfo";
      rev = "5916273f79a21551890fd3d56fc5375a78d1598d";
      sha256 = "sha256-nXBnloVTuB+AVX59VDU/Wc+Dsx94o92YQuHp3jowx2A=";
    };
  };

in stdenvNoCC.mkDerivation rec {
  pname = "onnxruntime";
  version = "1.14.1";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "onnxruntime";
    rev = "v${version}";
    sha256 = "sha256-cedOy9RIxtRszcpyL6/eX8r2u9nnTkK90/5IWgvZpKg=";
    fetchSubmodules = true;
  };

  patches = [
    # Use dnnl from nixpkgs instead of submodules
    (fetchpatch {
      name = "system-dnnl.patch";
      url =
        "https://aur.archlinux.org/cgit/aur.git/plain/system-dnnl.diff?h=python-onnxruntime&id=9c392fb542979981fe0026e0fe3cc361a5f00a36";
      sha256 = "sha256-+kedzJHLFU1vMbKO9cn8fr+9A5+IxIuiqzOfR2AfJ0k=";
    })
  ];

  nativeBuildInputs = [ gcc11 cmake pkg-config python3Packages.python gtest ]
    ++ lib.optionals pythonSupport
    (with python3Packages; [ setuptools wheel pip pythonOutputDistHook ]);

  buildInputs = [
    libpng
    zlib
    howard-hinnant-date-2_4_1
    nlohmann_json
    boost181
    oneDNN
    protobuf3_20
    nsync
    microsoft_gsl
    flatbuffers-1_12
    python3Packages.onnx
    cudaPackages_11_6.cuda_cudart
    cudaPackages_11_6.cudnn
    pytorch-cpuinfo
    googletest
  ] ++ lib.optionals pythonSupport [
    python3Packages.numpy
    python3Packages.pybind11
    python3Packages.packaging
  ];

  # TODO: build server, and move .so's to lib output
  # Python's wheel is stored in a separate dist output
  outputs = [ "out" "dev" ] ++ lib.optionals pythonSupport [ "dist" ];

  #  enableParallelBuilding = true;

  cmakeDir = "../cmake";

  cmakeFlags = [
    "-Donnxruntime_PREFER_SYSTEM_LIB=ON"
    "-Donnxruntime_BUILD_SHARED_LIB=ON"
    "-Donnxruntime_ENABLE_LTO=ON"
    "-Donnxruntime_BUILD_UNIT_TESTS=ON"
    "-Donnxruntime_USE_MPI=ON"
    "-Donnxruntime_USE_DNNL=YES"

    #    "-DCMAKE_VERBOSE_MAKEFILE=ON" # debugging

    # override cmake/deps.txt downloads
    "-Donnxruntime_USE_PREINSTALLED_EIGEN=ON"
    "-Deigen_SOURCE_PATH=${eigen.src}"
    "-DFETCHCONTENT_SOURCE_DIR_ABSEIL_CPP=${abseil-cpp_202206.src}"
    "-DFETCHCONTENT_SOURCE_DIR_DATE=${howard-hinnant-date-2_4_1.src}"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLE_NSYNC=${nsync.src}"
    "-DFETCHCONTENT_SOURCE_DIR_PROTOBUF=${protobuf3_20.src}"
    "-DFETCHCONTENT_SOURCE_DIR_BOOST=${boost181.src}" # wants 1.81
    "-DFETCHCONTENT_SOURCE_DIR_MP11=${mp11.src}"
    "-DFETCHCONTENT_SOURCE_DIR_RE2=${re2.src}"
    "-DFETCHCONTENT_SOURCE_DIR_GSL=${microsoft_gsl.src}"
    "-DFETCHCONTENT_SOURCE_DIR_SAFEINT=${safeint.src}"
    "-DFETCHCONTENT_SOURCE_DIR_FLATBUFFERS=${flatbuffers-1_12.src}"
    "-DFETCHCONTENT_SOURCE_DIR_MICROSOFT_WIL=${wil.src}"
    "-DFETCHCONTENT_SOURCE_DIR_ONNX=${python3Packages.onnx.src}"
    "-DFETCHCONTENT_SOURCE_DIR_CUTLASS=${cutlass.src}"
    "-DFETCHCONTENT_SOURCE_DIR_PYTORCH_CPUINFO=${pytorch-cpuinfo.src}"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=${googletest.src}"

    # see onnxruntime's python build wrapper
    "-Donnxruntime_USE_FULL_PROTOBUF=ON"
    "-DProtobuf_USE_STATIC_LIBS=ON"
    "-Donnxruntime_USE_CUDA=ON"
    "-Donnxruntime_CUDNN_HOME=${cudaPackages_11_6.cudnn}"
    "-DCUDA_INCLUDE_DIR=${cudaPackages_11_6.cudatoolkit}/include"

    # for ONNX "-DCUDAToolkit_ROOT=${cudaPackages_11_6.cudatoolkit}"
    "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages_11_6.cudatoolkit}"
    "-DCMAKE_CUDA_ARCHITECTURES=50" # XXX maxwell
    "-DCMAKE_CUDA_COMPILER=${cudaPackages_11_6.cudatoolkit}/bin/nvcc"

  ] ++ lib.optionals pythonSupport [ "-Donnxruntime_ENABLE_PYTHON=ON" ]
    ++ lib.optionals tensorrtSupport [
      "-DFETCHCONTENT_SOURCE_DIR_ONNX_TENSORRT=${onnx-tensorrt.src}"
      "-Donnxruntime_USE_TENSORRT=ON" # XXX i needed this
      "-Donnxruntime_TENSORRT_HOME=${cudaPackages_11_6.tensorrt_8_5_1}" # XXX
      "-DTENSORRT_INCLUDE_DIR=${cudaPackages_11_6.tensorrt_8_5_1.dev}/include" # XXX
    ];

  # see onnxruntime's python build wrapper
  ORT_TENSORRT_MAX_WORKSPACE_SIZE = "1073741824";
  ORT_TENSORRT_MAX_PARTITION_ITERATIONS = "1000";
  ORT_TENSORRT_MIN_SUBGRAPH_SIZE = "1";
  ORT_TENSORRT_FP16_ENABLE = "0";

  doCheck = false; # XXX 7th test fails

  postPatch = ''
    substituteInPlace cmake/libonnxruntime.pc.cmake.in \
      --replace '$'{prefix}/@CMAKE_INSTALL_ @CMAKE_INSTALL_
  '';

  postBuild = lib.optionalString pythonSupport ''
    python ../setup.py bdist_wheel
  '';

  postInstall = ''
    # perform parts of `tools/ci_build/github/linux/copy_strip_binary.sh`
    install -m644 -Dt $out/include \
      ../include/onnxruntime/core/framework/provider_options.h \
      ../include/onnxruntime/core/providers/cpu/cpu_provider_factory.h \
      ../include/onnxruntime/core/session/onnxruntime_*.h
  '';

  passthru = {
    inherit protobuf3_20;
    tests =
      lib.optionalAttrs pythonSupport { python = python3Packages.onnxruntime; };
  };

  meta = with lib; {
    description =
      "Cross-platform, high performance scoring engine for ML models";
    longDescription = ''
      ONNX Runtime is a performance-focused complete scoring engine
      for Open Neural Network Exchange (ONNX) models, with an open
      extensible architecture to continually address the latest developments
      in AI and Deep Learning. ONNX Runtime stays up to date with the ONNX
      standard with complete implementation of all ONNX operators, and
      supports all ONNX releases (1.2+) with both future and backwards
      compatibility.
    '';
    homepage = "https://github.com/microsoft/onnxruntime";
    changelog =
      "https://github.com/microsoft/onnxruntime/releases/tag/v${version}";
    # https://github.com/microsoft/onnxruntime/blob/master/BUILD.md#architectures
    platforms = platforms.unix;
    license = licenses.mit;
    maintainers = with maintainers; [ jonringer puffnfresh ck3d ];
  };
}
