{ stdenv, stdenvNoCC, lib, fetchFromGitHub, fetchpatch, fetchurl, pkg-config
, cmake, python3Packages, libpng, zlib, eigen, nlohmann_json, boost181, oneDNN
, abseil-cpp_202206, gtest, pythonSupport ? false, tensorrtSupport ? false
, nsync, re2, cudaPackages_11_6, microsoft_gsl, python3, callPackage, fetchgit
, autoPatchelfHook, addOpenGLRunpath, pkgs, protobuf3_20, flatbuffers
, breakpointHook, linkFarm, substituteAll, symlinkJoin }:

# export LD_LIBRARY_PATH=/run/opengl-driver/lib:/nix/store/chpc1c8qw7fzl84pkix3rw1b85ymbi8f-onnxruntime-1.14.1/lib
# for x in `find /nix/store -name "libonnxruntime_providers_shared.so"`; do echo $x; nix-store --query --roots $x; done

# make[1]: Leaving directory '/build/onnxruntime/build'
# /nix/store/fqfi0m3fw3szj3n99r5n359579808bh6-cmake-3.25.3/bin/cmake -E cmake_progress_start /build/onnxruntime/build/CMakeFiles 0
# adding opengl runpath to all executables and libs
# buildPhase completed in 47 minutes 57 seconds
# running tests
# check flags: -j8 SHELL=/nix/store/7q1b1bsmxi91zci6g8714rcljl620y7f-bash-5.2-p15/bin/bash VERBOSE=y test
# Running tests...
# /nix/store/fqfi0m3fw3szj3n99r5n359579808bh6-cmake-3.25.3/bin/ctest --force-new-ctest-process 
# Test project /build/onnxruntime/build
#     Start 1: onnxruntime_test_all
#     Start 2: onnx_test_pytorch_converted
#     Start 3: onnx_test_pytorch_operator
#     Start 4: onnxruntime_shared_lib_test
#     Start 5: onnxruntime_global_thread_pools_test
#     Start 6: onnxruntime_api_tests_without_env
#     Start 7: onnxruntime_customopregistration_test
# 1/7 Test #6: onnxruntime_api_tests_without_env .......   Passed    0.01 sec
# 2/7 Test #7: onnxruntime_customopregistration_test ...   Passed    0.18 sec
# 3/7 Test #3: onnx_test_pytorch_operator ..............   Passed    0.33 sec
# 4/7 Test #2: onnx_test_pytorch_converted .............   Passed    0.53 sec
# 5/7 Test #4: onnxruntime_shared_lib_test .............Subprocess aborted***Exception:   1.24 sec
# [==========] Running 76 tests from 3 test suites.
# [----------] Global test environment set-up.
# [----------] 70 tests from CApiTest
# [ RUN      ] CApiTest.dim_param
# [       OK ] CApiTest.dim_param (70 ms)
# [ RUN      ] CApiTest.SparseOutputModel
# [       OK ] CApiTest.SparseOutputModel (44 ms)
# [ RUN      ] CApiTest.SparseInputModel
# [       OK ] CApiTest.SparseInputModel (5 ms)
# [ RUN      ] CApiTest.custom_op_handler
# Running custom op inference
# Running simple inference with cuda provider
# unknown file: Failure
#   C++ exception with description "/build/onnxruntime/onnxruntime/core/providers/cuda/cuda_call.cc:124 std::conditional_t<THRW, void, onnxruntime::common::Status> onnxruntime::CudaCall(ERRTYPE, const char*, const char*, ERRTYPE, const char*) [with ERRTYPE = cudaError; bool THRW = true; std::conditional_t<THRW, void, onnxruntime::common::Status> = void] /build/onnxruntime/onnxruntime/core/providers/cuda/cuda_call.cc:117 std::conditional_t<THRW, void, onnxruntime::common::Status> onnxruntime::CudaCall(ERRTYPE, const char*, const char*, ERRTYPE, const char*) [with ERRTYPE = cudaError; bool THRW = true; std::conditional_t<THRW, void, onnxruntime::common::Status> = void] CUDA failure 35: CUDA driver version is insufficient for CUDA runtime version ; GPU=0 ; hostname=localhost ; expr=cudaSetDevice(info_.device_id);

# existing:
# ./pj72h6n21clvzc7b9zvdljv4bani9qac-onnxruntime-1.14.1/lib/libonnxruntime_providers_shared.so
# ./afaabz5lmq7mn2anz4q75ym3jz57xs6c-onnxruntime-1.14.1/lib/libonnxruntime_providers_shared.so
# ./a3m9c7d330508d22yb9qp1znymvxpgfd-onnxruntime-1.14.1/lib/libonnxruntime_providers_shared.so
# ./kr3pdmvvakf2y0g3kgcb7d2hy0171ngg-onnxruntime-1.13.1/lib/libonnxruntime_providers_shared.so
# ./74bfq8k04kidf2vzq7qkpq4lw9fbq886-onnxruntime-1.13.1/lib/libonnxruntime_providers_shared.so
# /nix/store/nbyxxf72f04rbr1cqk1rmcandz5qxyhk-onnxruntime-1.14.1

# to build with cmake/deps.txt downloads: NIXPKGS_ALLOW_UNFREE=1 nix-build --option sandbox false --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {tensorrtSupport=true;}'
# without: NIXPKGS_ALLOW_UNFREE=1 --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {tensorrtSupport=true;}'
# debug shared lib stuff: LD_DEBUG=libs

let
  # We do not have access to /run/opengl-driver/lib in the sandbox,
  # so use a stub instead.
  #cudaStub = linkFarm "cuda-stub" [{
  #  name = "libcuda.so.1";
  #  path = "${cudaPackages_11_6.cudatoolkit}/lib/stubs/libcuda.so";
  #}];

  srcdeps = linkFarm "onnxruntime-1.14.1-srcdeps" [
    {
      name = "protobuf";
      path = fetchFromGitHub {
        owner = "protocolbuffers";
        repo = "protobuf";
        rev = "v3.20.2";
        sha256 = "sha256-7hLTIujvYIGRqBQgPHrCq0XOh0GJrePBszXJnBFaXVM=";
      };
    }
    {
      name = "flatbuffers";
      path = fetchFromGitHub {
        owner = "google";
        repo = "flatbuffers";
        rev = "v1.12.0";
        sha256 = "sha256-L1B5Y/c897Jg9fGwT2J3+vaXsZ+lfXnskp8Gto1p/Tg=";
      };
    }
    {
      name = "howard-hinnant-date";
      path = fetchFromGitHub {
        owner = "HowardHinnant";
        repo = "date";
        rev = "v2.4.1";
        sha256 = "sha256-BYL7wxsYRI45l8C3VwxYIIocn5TzJnBtU0UZ9pHwwZw=";
      };
    }
    {
      name = "nsync";
      path = fetchFromGitHub {
        owner = "google";
        repo = "nsync";
        rev = "1.23.0";
        sha256 = "sha256-4xvR47MbYaWBf+jKL6xH2g0NvIgC4Pz1mBNR7eRQY8A=";
      };
    }
    {
      name = "onnx";
      path = fetchFromGitHub {
        owner = "onnx";
        repo = "onnx";
        rev = "v1.13.0";
        sha256 = "sha256-D8POBAkZVr0O5i4qsSuYRkDfL8WsDTqzgNACmmkFwGs=";
      };
    }
    {
      name = "safeint";
      path = fetchFromGitHub {
        owner = "dcleblanc";
        repo = "SafeInt";
        rev = "ff15c6ada150a5018c5ef2172401cb4529eac9c0";
        sha256 = "sha256-PK1ce4C0uCR4TzLFg+elZdSk5DdPCRhhwT3LvEwWnPU=";
      };
    }
    {
      name = "wil";
      path = fetchFromGitHub {
        owner = "microsoft";
        repo = "wil";
        rev = "5f4caba4e7a9017816e47becdd918fcc872039ba";
        sha256 = "sha256-nbiDtBZsni7hp9fROBB1D4j7ssBZOgG5goeb6/lSS20=";
      };
    }
    {
      name = "cutlass";
      path = fetchFromGitHub {
        owner = "NVIDIA";
        repo = "cutlass";
        rev = "v2.11.0";
        sha256 = "sha256-P8A1NEcYp5o15dB+d0zzSLwVWv472txLY7zDMYb70o4=";
      };
    }
    {
      name = "onnx-tensorrt";
      # fetchFromGitHub's fetchSubmodules doesn't work
      path = fetchgit {
        url = "https://github.com/onnx/onnx-tensorrt.git";
        rev = "369d6676423c2a6dbf4a5665c4b5010240d99d3c";
        sha256 = "sha256-WopvaKYdTcNBcZ4tnxXmtgfxuLLFoAc+u57/bzBNXbU=";
        fetchSubmodules = true;
      };
    }
    {
      name = "mp11";
      path = fetchFromGitHub {
        owner = "boostorg";
        repo = "mp11";
        rev = "boost-1.79.0";
        sha256 = "sha256-ZxgPDLvpISrjpEHKpLGBowRKGfSwTf6TBfJD18yw+LM=";
      };
    }
    {
      name = "googletest";
      path = fetchFromGitHub {
        owner = "google";
        repo = "googletest";
        rev = "519beb0e52c842729b4b53731d27c0e0c32ab4a2";
        sha256 = "sha256-6LG2Q9QSQBG6oynBkgdtXBsUra6LXPOZWR6i0dPMdeY=";
      };
    }
    {
      name = "pytorch-cpuinfo";
      path = fetchFromGitHub {
        owner = "pytorch";
        repo = "cpuinfo";
        rev = "5916273f79a21551890fd3d56fc5375a78d1598d";
        sha256 = "sha256-nXBnloVTuB+AVX59VDU/Wc+Dsx94o92YQuHp3jowx2A=";
      };
    }
  ];

  # cudaEnv = symlinkJoin {
  #     name = "onnxruntime-cuda-env";
  #     paths = with cudaPackages_11_6; [
  #       cuda_cudart cuda_nvcc libcublas libcufft # libcurand libcusparse
  #     ];
  #     postBuild = ''
  #       ln -s ${addOpenGLRunpath.driverLink}/lib/libcuda.so $out/lib
  #       ln -s lib $out/lib64
  #     '';
  #   };

in cudaPackages_11_6.backendStdenv.mkDerivation rec {
  pname = "onnxruntime";
  version = "1.14.1";

  # fetchFromGitHub's fetchSubmodules doesn't work
  src = fetchgit {
    url = "https://github.com/microsoft/onnxruntime.git";
    rev = "v${version}";
    sha256 = "sha256-4maQbtafOteoYloD57vg55vl9utslMPP4CF/TYBZN1A=";
    fetchSubmodules = true;
    deepClone = true;
  };

  patches = [
    # Use dnnl from nixpkgs instead of submodules
    (fetchpatch {
      name = "system-dnnl.patch";
      url =
        "https://aur.archlinux.org/cgit/aur.git/plain/system-dnnl.diff?h=python-onnxruntime&id=9c392fb542979981fe0026e0fe3cc361a5f00a36";
      sha256 = "sha256-+kedzJHLFU1vMbKO9cn8fr+9A5+IxIuiqzOfR2AfJ0k=";
    })
    (substituteAll {
      src = ./tests-ld-library-path.patch;
      cudalibpath = "${cudaPackages_11_6.cudatoolkit}/lib/stubs";
    })
    #./no-werror.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    python3Packages.python
    gtest
    autoPatchelfHook
    cudaPackages_11_6.autoAddOpenGLRunpathHook
    breakpointHook
  ] ++ lib.optionals pythonSupport
    (with python3Packages; [ setuptools wheel pip pythonOutputDistHook ]);

  buildInputs = [
    libpng
    zlib
    nlohmann_json
    oneDNN
    cudaPackages_11_6.cudatoolkit
    cudaPackages_11_6.cudnn
    # cudaPackages_11_6.libcublas # already in cudatoolkit
    # cudaPackages_11_6.cuda_cudart # already in cudatoolkit
    #    flatbuffers
    #    protobuf3_20
    #    python3Packages.onnx
    #    howard-hinnant-date-2_4_1
    #    boost181
    #    nsync
    #    microsoft_gsl
    #    flatbuffers-1_12_0
    #    pytorch-cpuinfo
    #    googletest
  ] ++ lib.optionals pythonSupport [
    python3Packages.numpy
    python3Packages.pybind11
    python3Packages.packaging
  ] ++ lib.optionals tensorrtSupport [ cudaPackages_11_6.tensorrt_8_5_1 ];

  # TODO: build server, and move .so's to lib output
  # Python's wheel is stored in a separate dist output
  outputs = [ "out" "dev" ] ++ lib.optionals pythonSupport [ "dist" ];

  enableParallelBuilding = true;

  env.LDFLAGS = "-L${cudaPackages_11_6.cudatoolkit}/lib/stubs";
  env.NIX_CFLAGS_COMPILE = "-Wno-unused-parameter";

  cmakeDir = "../cmake";

  cmakeFlags = [
    # from original onnxruntime default.nix
    "-Donnxruntime_PREFER_SYSTEM_LIB=ON"
    "-Donnxruntime_BUILD_SHARED_LIB=ON"
    "-Donnxruntime_ENABLE_LTO=ON"
    "-Donnxruntime_BUILD_UNIT_TESTS=ON"
    "-Donnxruntime_USE_MPI=ON"
    "-Donnxruntime_USE_DNNL=YES"
    "-Donnxruntime_USE_PREINSTALLED_EIGEN=ON"
    "-Deigen_SOURCE_PATH=${eigen.src}"

    # override cmake/deps.txt downloads
    "-DFETCHCONTENT_SOURCE_DIR_ABSEIL_CPP=${abseil-cpp_202206.src}"
    "-DFETCHCONTENT_SOURCE_DIR_DATE=${srcdeps}/howard-hinnant-date"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLE_NSYNC=${srcdeps}/nsync"
    "-DFETCHCONTENT_SOURCE_DIR_PROTOBUF=${srcdeps}/protobuf"
    "-DFETCHCONTENT_SOURCE_DIR_FLATBUFFERS=${srcdeps}/flatbuffers"
    "-DFETCHCONTENT_SOURCE_DIR_BOOST=${boost181.src}"
    "-DFETCHCONTENT_SOURCE_DIR_MP11=${srcdeps}/mp11"
    "-DFETCHCONTENT_SOURCE_DIR_RE2=${re2.src}"
    "-DFETCHCONTENT_SOURCE_DIR_GSL=${microsoft_gsl.src}"
    "-DFETCHCONTENT_SOURCE_DIR_SAFEINT=${srcdeps}/safeint"
    "-DFETCHCONTENT_SOURCE_DIR_MICROSOFT_WIL=${srcdeps}/wil"
    "-DFETCHCONTENT_SOURCE_DIR_ONNX=${srcdeps}/onnx"
    "-DFETCHCONTENT_SOURCE_DIR_CUTLASS=${srcdeps}/cutlass"
    "-DFETCHCONTENT_SOURCE_DIR_PYTORCH_CPUINFO=${srcdeps}/pytorch-cpuinfo"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=${srcdeps}/googletest"

    # debugging
    "-DCMAKE_VERBOSE_MAKEFILE=ON"

    # see onnxruntime's tools/ci_build/build.py
    "-Donnxruntime_USE_FULL_PROTOBUF=ON"
    "-DProtobuf_USE_STATIC_LIBS=ON"
    "-Donnxruntime_USE_CUDA=ON"
    "-Donnxruntime_CUDNN_HOME=${cudaPackages_11_6.cudnn}"
    #    "-DCUDA_INCLUDE_DIR=${cudaPackages_11_6.cudatoolkit}/include" # handled

    # cmake-specific flag to tell nvcc which platforms to generate code for
    #    "-DCMAKE_CUDA_ARCHITECTURES=50;52;53" # XXX maxwell, how to generalize? # handled

    # for onnx-tensorrt
    #    "-DCUDA_TOOLKIT_ROOT_DIR=${cudaPackages_11_6.cudatoolkit}" # handled
    #    "-DCMAKE_CUDA_COMPILER=${cudaPackages_11_6.cudatoolkit}/bin/nvcc" # handled

  ] ++ lib.optionals pythonSupport [ "-Donnxruntime_ENABLE_PYTHON=ON" ]
    ++ lib.optionals tensorrtSupport [
      "-DFETCHCONTENT_SOURCE_DIR_ONNX_TENSORRT=${srcdeps}/onnx-tensorrt"
      "-Donnxruntime_USE_TENSORRT=ON"
      "-Donnxruntime_TENSORRT_HOME=${cudaPackages_11_6.tensorrt_8_5_1}"
      #      "-DTENSORRT_HOME=${cudaPackages_11_6.tensorrt_8_5_1}"
      "-DTENSORRT_INCLUDE_DIR=${cudaPackages_11_6.tensorrt_8_5_1.dev}/include"
    ];

  postPatch = ''
    substituteInPlace cmake/libonnxruntime.pc.cmake.in \
      --replace '$'{prefix}/@CMAKE_INSTALL_ @CMAKE_INSTALL_
  '';

  # see onnxruntime's python tools/ci_build/build.py
  preBuild = lib.optionalString tensorrtSupport ''
    export ORT_TENSORRT_MAX_WORKSPACE_SIZE=1073741824
    export ORT_TENSORRT_MAX_PARTITION_ITERATIONS=1000
    export ORT_TENSORRT_MIN_SUBGRAPH_SIZE=1
    export ORT_TENSORRT_FP16_ENABLE=0
  '';

  postBuild = lib.optionalString pythonSupport ''
    python ../setup.py bdist_wheel
  '';

  doCheck = false; # XXX 7th test fails

  preCheck = ''
    export LD_LIBRARY_PATH=${cudaPackages_11_6.cudatoolkit}/lib/stubs
    echo "running autopatchelf"
    autoPatchelf "$out"
    echo "adding opengl runpath to all executables and libs"
    find $out -type f | while read lib; do
      addOpenGLRunpath "$lib"
    done
  '';

  postInstall = ''
    # perform parts of `tools/ci_build/github/linux/copy_strip_binary.sh`
    install -m644 -Dt $out/include \
      ../include/onnxruntime/core/framework/provider_options.h \
      ../include/onnxruntime/core/providers/cpu/cpu_provider_factory.h \
      ../include/onnxruntime/core/session/onnxruntime_*.h
  '';

  #  passthru = {
  #    inherit protobuf3_20;
  #    tests =
  #      lib.optionalAttrs pythonSupport { python = python3Packages.onnxruntime; }#;
  #  };

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
