{ stdenv, stdenvNoCC, lib, fetchFromGitHub, fetchpatch, fetchurl, pkg-config
, cmake, python3Packages, libpng, eigen, nlohmann_json, oneDNN, gtest
, pythonSupport ? false, tensorrtSupport ? false, cudaPackages_11_8, python3
, callPackage, fetchgit, autoPatchelfHook, addOpenGLRunpath, pkgs
, breakpointHook, linkFarm, substituteAll, symlinkJoin, git, unstable }:

# from https://github.com/microsoft/onnxruntime/issues/8298
#./build.sh --parallel --build --update --config Release --cuda_home /usr/local/cuda --cudnn_home /usr/local/cuda/lib64 --tensorrt_home /home/cgarcia/Documentos/tensorrt/TensorRT-7.2.3.4 --use_tensorrt --build_wheel --cmake_extra_defines ONNXRUNTIME_VERSION=$(cat ./VERSION_NUMBER) --cuda_version=11.4 --enable_pybind

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

# [----------] Global test environment tear-down
# [==========] 3792 tests from 260 test suites ran. (79778 ms total)
# [  PASSED  ] 3768 tests.
# [  FAILED  ] 24 tests, listed below:
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_to_float
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul_Add
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul_Add_Relu
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Div1
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Div2
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Sub1
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Sub2
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Abs
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Elu
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul_Exp
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_LeakyRelu
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Abs_Log
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Add_Round
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Sigmoid
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul_Softplus
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Abs_Sqrt
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Mul_Tanh
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_36_ops
# [  FAILED  ] DnnlMatMulIntegerFusion.MatMulInteger_Cast_Elu_LeakyRelu
# [  FAILED  ] MathOpTest.CosDouble
# [  FAILED  ] Random.RandomNormalGpu
# [  FAILED  ] Random.RandomUniformGpu
# [  FAILED  ] FusedMatMulOpTest.DoubleTypeNoTranspose

# 24 FAILED TESTS
#   YOU HAVE 9 DISABLED TESTS

# 86% tests passed, 1 tests failed out of 7

# Total Test time (real) =  80.79 sec

# The following tests FAILED:
#           1 - onnxruntime_test_all (Failed)
# Errors while running CTest
# make: *** [Makefile:94: test] Error 8
# build failed in checkPhase with exit code 2

# 2023-07-14 11:17:39.978017855 [E:onnxruntime:MatMulInteger:MatMulInteger, sequential_executor.cc:494 ExecuteKernel] Non-zero status code returned while running MatMulInteger node. Name:'matmul1' Status Message: CUBLAS failure 8: CUBLAS_STATUS_ARCH_MISMATCH ; GPU=0 ; hostname=thinknix512 ; expr=cublasGemmEx( cublas, CUBLAS_OP_N, CUBLAS_OP_N, n, m, k, &alpha, ldb_aligned == ldb ? b : b_padded.get(), CUDA_R_8I, ldb_aligned, lda_aligned == lda ? a : a_padded.get(), CUDA_R_8I, lda_aligned, &beta, c, CUDA_R_32I, ldc, CUDA_R_32I, CUBLAS_GEMM_DFALT);

# https://github.com/NVIDIA/FasterTransformer/issues/25

# CUBLAS_STATUS_ARCH_MISMATCH

# The function requires a feature absent from the device architecture; usually caused by compute capability lower than 5.0.

#   To correct: compile and run the application on a device with appropriate compute capability.

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
      # fetchFromGitHub's fetchSubmodules doesn't work
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

  # fetchFromGitHub's fetchSubmodules doesn't work
  src = fetchFromGitHub {
    url = "https://github.com/microsoft/onnxruntime.git";
    owner = "microsoft";
    repo = "onnxruntime";
    rev = "v${version}";
    sha256 = "sha256-6s0iYGbh7cclHAXJ1jGktL3o5JdyqMsGwxe53vANObA=";
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

  buildInputs = [
    libpng
    nlohmann_json
    oneDNN
    cuda_joined
    git
  ] ++ lib.optionals pythonSupport [
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
#    "-DCMAKE_PREFIX_PATH=/home/chrism/projects/onnxruntime/build/Linux/Release/installed"
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
    "-DCMAKE_VERBOSE_MAKEFILE=ON"

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

  doCheck = true; # XXX 7th test fails

  preCheck = ''
    export LD_LIBRARY_PATH=${addOpenGLRunpath.driverLink}/lib
    # echo "running autopatchelf"
    # autoPatchelf "$out"
    # echo "adding opengl runpath to all executables and libs"
    # find $out -type f | while read lib; do
    #   addOpenGLRunpath "$lib"
    # done
  '';

  postCheck = "${cmake}/bin/ctest --build-config Release --verbose --timeout 10800";
    
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
