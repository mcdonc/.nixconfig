{ pkgs, lib, fetchFromGitHub, fetchpatch, fetchurl, pkg-config , cmake,
python3Packages, libpng, eigen, nlohmann_json, oneDNN, gtest ,
cudaPackages_11_8, python3, callPackage, fetchgit, autoPatchelfHook ,
addOpenGLRunpath, breakpointHook, linkFarm, substituteAll, symlinkJoin , git,
unstable, pythonSupport ? true, tensorrtSupport ? true, runTests ? true }:

let
  onnxver = "1.15.1";

  srcdeps = linkFarm "onnxruntime-${onnxver}-srcdeps" [
    {
      name = "protobuf";
      path = fetchFromGitHub {
        owner = "protocolbuffers";
        repo = "protobuf";
        rev = "v21.12";
        sha256 = "sha256-VZQEFHq17UsTH5CZZOcJBKiScGV2xPJ/e6gkkVliRCU=";
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
        rev = "v1.14.0";
        sha256 = "sha256-f+s25Y/jGosaSdoZY6PE3j6pENkfDcD+IQndrbtuzWg=";
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
        rev = "v3.0.0";
        sha256 = "sha256-YPD5Sy6SvByjIcGtgeGH80TEKg2BtqJWSg46RvnJChY=";
      };
    }
    {
      name = "onnx-tensorrt";
      path = fetchFromGitHub {
        owner = "onnx";
        repo = "onnx-tensorrt";
        rev = "ba6a4fb34fdeaa3613bf981610c657e7b663a699";
        sha256 = "sha256-BcvkX0hX3AmogTFwILs86/MuITkknfuCAaaOuBKRjv8=";
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
    {
      name = "abseil";
      path = fetchFromGitHub {
        owner = "abseil";
        repo = "abseil-cpp";
        rev = "20220623.1";
        sha256 = "sha256-Od1FZOOWEXVQsnZBwGjDIExi6LdYtomyL0STR44SsG8=";
      };
    }
    {
      name = "gsl";
      path = fetchFromGitHub {
        owner = "microsoft";
        repo = "GSL";
        rev = "v4.0.0";
        sha256 = "sha256-cXDFqt2KgMFGfdh6NGE+JmP4R0Wm9LNHM0eIblYe6zU=";
      };
    }
    {
      name = "re2";
      path = fetchFromGitHub {
        owner = "google";
        repo = "re2";
        rev = "2022-06-01";
        sha256 = "sha256-UontAjOXpnPcOgoFHjf+1WSbCR7h58/U7nn4meT200Y=";
      };
    }

  ];

  cuda_joined = symlinkJoin {
    name = "cuda-joined-for-onnxruntime";
    paths = [ cudaPackages_11_8.cudatoolkit cudaPackages_11_8.cudnn ]
      ++ lib.optionals tensorrtSupport [
        cudaPackages_11_8.tensorrt
        cudaPackages_11_8.tensorrt.dev
      ];
  };

in cudaPackages_11_8.backendStdenv.mkDerivation rec {
  pname = "onnxruntime";
  version = "${onnxver}";

  __noChroot = true;

  src = fetchFromGitHub {
    url = "https://github.com/microsoft/onnxruntime.git";
    owner = "microsoft";
    repo = "onnxruntime";
    rev = "v${version}";
    sha256 = "sha256-DeNMKj5b1QdHboKfOcltyBYJve0qABGRWLt1iM3JPgM=";
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
      cudalibpath = "${addOpenGLRunpath.driverLink}/lib";
    })
    #./no-werror.patch
  ];

  nativeBuildInputs = [
    unstable.cmake
    pkg-config
    #    python3Packages.python
    gtest
    autoPatchelfHook
    python3
    cudaPackages_11_8.autoAddOpenGLRunpathHook
    #    breakpointHook
  ] ++ lib.optionals pythonSupport
    (with python3Packages; [ setuptools wheel pip pythonOutputDistHook ]);

  buildInputs = [ libpng nlohmann_json oneDNN cuda_joined git ]
    ++ lib.optionals pythonSupport [
      python3Packages.numpy
      python3Packages.pybind11
      python3Packages.packaging
    ];

  # TODO: build server, and move .so's to lib output
  # Python's wheel is stored in a separate dist output
  outputs = [ "out" "dev" ] ++ lib.optionals pythonSupport [ "dist" ];

  enableParallelBuilding = true;

  cmakeDir = "../cmake";
  #NIX_CFLAGS_COMPILE = ["-O2"];

  cmakeFlags = [
    # taken from a successful invocation of
    # ./build.sh --config Release --build_shared_lib --compile_no_warning_as_error --skip_submodule_sync --use_cuda --cuda_home=/usr/local/cuda-11.8 --cudnn_home=/usr/lib --parallel
    # on ubuntu
    "--compile-no-warning-as-error"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_TLS_VERIFY=ON"
    "-DFETCHCONTENT_QUIET=OFF"
    "-DOnnxruntime_GCOV_COVERAGE=OFF"
    "-DPYTHON_EXECUTABLE=${python3}/bin/python3"
    "-DPython_EXECUTABLE=${python3}/bin/python3"
    "-Donnxruntime_ARMNN_BN_USE_CPU=ON"
    "-Donnxruntime_ARMNN_RELU_USE_CPU=ON"
    "-Donnxruntime_BUILD_APPLE_FRAMEWORK=OFF"
    "-Donnxruntime_BUILD_BENCHMARKS=OFF"
    "-Donnxruntime_BUILD_CSHARP=OFF"
    "-Donnxruntime_BUILD_JAVA=OFF"
    "-Donnxruntime_BUILD_MS_EXPERIMENTAL_OPS=OFF"
    "-Donnxruntime_BUILD_NODEJS=OFF"
    "-Donnxruntime_BUILD_OBJC=OFF"
    "-Donnxruntime_BUILD_SHARED_LIB=ON"
    "-Donnxruntime_BUILD_WEBASSEMBLY=OFF"
    "-Donnxruntime_BUILD_WEBASSEMBLY_STATIC_LIB=OFF"
    "-Donnxruntime_DISABLE_CONTRIB_OPS=ON" # XXX
    "-Donnxruntime_DISABLE_EXCEPTIONS=OFF"
    "-Donnxruntime_DISABLE_ML_OPS=OFF"
    "-Donnxruntime_DISABLE_RTTI=OFF"
    "-Donnxruntime_ENABLE_CPU_FP16_OPS=OFF"
    "-Donnxruntime_ENABLE_CUDA_LINE_NUMBER_INFO=OFF"
    "-Donnxruntime_ENABLE_CUDA_PROFILING=OFF"
    "-Donnxruntime_ENABLE_EXTERNAL_CUSTOM_OP_SCHEMAS=OFF"
    "-Donnxruntime_ENABLE_LANGUAGE_INTEROP_OPS=OFF"
    "-Donnxruntime_ENABLE_LAZY_TENSOR=OFF"
    "-Donnxruntime_ENABLE_LTO=OFF"
    "-Donnxruntime_ENABLE_MEMLEAK_CHECKER=OFF"
    "-Donnxruntime_ENABLE_MEMORY_PROFILE=OFF"
    "-Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF"
    "-Donnxruntime_ENABLE_NVTX_PROFILE=OFF"
    "-Donnxruntime_ENABLE_PYTHON=OFF"
    "-Donnxruntime_ENABLE_ROCM_PROFILING=OFF"
    "-Donnxruntime_ENABLE_TRAINING=OFF"
    "-Donnxruntime_ENABLE_TRAINING_APIS=OFF"
    "-Donnxruntime_ENABLE_TRAINING_OPS=OFF"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_API_EXCEPTION_CATCHING=OFF"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_DEBUG_INFO=OFF"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_EXCEPTION_CATCHING=ON"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_EXCEPTION_THROWING=ON"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_PROFILING=OFF"
    "-Donnxruntime_ENABLE_WEBASSEMBLY_THREADS=OFF"
    "-Donnxruntime_EXTENDED_MINIMAL_BUILD=OFF"
    "-Donnxruntime_GENERATE_TEST_REPORTS=ON"
    "-Donnxruntime_MINIMAL_BUILD=OFF"
    "-Donnxruntime_MINIMAL_BUILD_CUSTOM_OPS=OFF"
    "-Donnxruntime_NVCC_THREADS=0"
    "-Donnxruntime_PYBIND_EXPORT_OPSCHEMA=OFF"
    "-Donnxruntime_REDUCED_OPS_BUILD=OFF"
    "-Donnxruntime_RUN_ONNX_TESTS=OFF"
    "-Donnxruntime_TVM_CUDA_RUNTIME=OFF"
    "-Donnxruntime_TVM_USE_HASH=OFF"
    "-Donnxruntime_USE_ACL=OFF"
    "-Donnxruntime_USE_ACL_1902=OFF"
    "-Donnxruntime_USE_ACL_1905=OFF"
    "-Donnxruntime_USE_ACL_1908=OFF"
    "-Donnxruntime_USE_ACL_2002=OFF"
    "-Donnxruntime_USE_ARMNN=OFF"
    "-Donnxruntime_USE_CANN=OFF"
    "-Donnxruntime_USE_DML=OFF"
    "-Donnxruntime_USE_DNNL=OFF"
    "-Donnxruntime_USE_JSEP=OFF"
    "-Donnxruntime_USE_LLVM=OFF"
    "-Donnxruntime_USE_MIGRAPHX=OFF"
    "-Donnxruntime_USE_MIMALLOC=OFF"
    "-Donnxruntime_USE_MPI=OFF"
    "-Donnxruntime_USE_NCCL=OFF"
    "-Donnxruntime_USE_NNAPI_BUILTIN=OFF"
    "-Donnxruntime_USE_RKNPU=OFF"
    "-Donnxruntime_USE_ROCM=OFF"
    "-Donnxruntime_USE_TELEMETRY=OFF"
    "-Donnxruntime_USE_TENSORRT=OFF"
    "-Donnxruntime_USE_TENSORRT_BUILTIN_PARSER=ON"
    "-Donnxruntime_USE_TVM=OFF"
    "-Donnxruntime_USE_VITISAI=OFF"
    "-Donnxruntime_USE_WINML=OFF"
    "-Donnxruntime_USE_XNNPACK=OFF"
    "-Donnxruntime_WEBASSEMBLY_RUN_TESTS_IN_BROWSER=OFF"

    # from original onnxruntime default.nix
    "-Donnxruntime_BUILD_UNIT_TESTS=ON"
    "-Donnxruntime_USE_PREINSTALLED_EIGEN=ON"
    "-Deigen_SOURCE_PATH=${eigen.src}"

    # override cmake/deps.txt downloads
    "-DFETCHCONTENT_SOURCE_DIR_ABSEIL_CPP=${srcdeps}/abseil"
    "-DFETCHCONTENT_SOURCE_DIR_DATE=${srcdeps}/howard-hinnant-date"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLE_NSYNC=${srcdeps}/nsync"
    "-DFETCHCONTENT_SOURCE_DIR_PROTOBUF=${srcdeps}/protobuf"
    "-DFETCHCONTENT_SOURCE_DIR_FLATBUFFERS=${srcdeps}/flatbuffers"
    "-DFETCHCONTENT_SOURCE_DIR_MP11=${srcdeps}/mp11"
    "-DFETCHCONTENT_SOURCE_DIR_RE2=${srcdeps}/re2"
    "-DFETCHCONTENT_SOURCE_DIR_GSL=${srcdeps}/gsl"
    "-DFETCHCONTENT_SOURCE_DIR_SAFEINT=${srcdeps}/safeint"
    "-DFETCHCONTENT_SOURCE_DIR_MICROSOFT_WIL=${srcdeps}/wil"
    "-DFETCHCONTENT_SOURCE_DIR_ONNX=${srcdeps}/onnx"
    "-DFETCHCONTENT_SOURCE_DIR_CUTLASS=${srcdeps}/cutlass"
    "-DFETCHCONTENT_SOURCE_DIR_PYTORCH_CPUINFO=${srcdeps}/pytorch-cpuinfo"
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=${srcdeps}/googletest"

    # debugging
    #"-DCMAKE_VERBOSE_MAKEFILE=ON"

    # see onnxruntime's tools/ci_build/build.py
    #    "-Donnxruntime_USE_FULL_PROTOBUF=ON"
    #    "-DProtobuf_USE_STATIC_LIBS=ON"
    "-Donnxruntime_USE_CUDA=ON"
    "-DCUDA_CUDA_LIBRARY=${cuda_joined}/lib/stubs"
    "-Donnxruntime_CUDA_HOME=${cuda_joined}"
    "-Donnxruntime_CUDNN_HOME=${cuda_joined}/lib"

  ] ++ lib.optionals pythonSupport [ "-Donnxruntime_ENABLE_PYTHON=ON" ]
    ++ lib.optionals tensorrtSupport [
      "-Donnxruntime_USE_TENSORRT_BUILTIN_PARSER=ON"
      "-DFETCHCONTENT_SOURCE_DIR_ONNX_TENSORRT=${srcdeps}/onnx-tensorrt"
      "-Donnxruntime_USE_TENSORRT=ON"
      "-Donnxruntime_TENSORRT_HOME=${cuda_joined}"
      "-DTENSORRT_HOME=${cuda_joined}"
      "-DTENSORRT_INCLUDE_DIR=${cuda_joined}/include"
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

  doCheck = runTests;

  preCheck = ''
    export LD_LIBRARY_PATH=${addOpenGLRunpath.driverLink}/lib
    # echo "running autopatchelf"
    # autoPatchelf "$out"
    # echo "adding opengl runpath to all executables and libs"
    # find $out -type f | while read lib; do
    #   addOpenGLRunpath "$lib"
    # done
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
