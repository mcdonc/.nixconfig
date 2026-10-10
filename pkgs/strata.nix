# Strata — declarative packaging of https://github.com/Niko1221/Strata
# (Qwen3.8-Flash-Next local LLM server) for keithmoon.
#
# What this builds:
#   bin/strata            the CUDA engine (compiled from source; no prebuilt
#                         engine exists for the version pinned here)
#   bin/strata-server     the OpenAI/Anthropic-compatible python server
#   share/strata/         serve/ + tools/ + data/ from the repo, plus
#                         llama.cpp's gguf-py (the pack-prep tools need it)
#
# The 72 GB of model GGUFs and the prepared packs/MTP draft layer are NOT in
# the store — they live in /var/lib/strata, fetched and prepared by systemd
# units declared in hosts/roles/strata.nix.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  cudaPackages_13,
  python3Packages,
  makeWrapper,
}:

let
  # v0.1.41-unreleased: no ready-made engine exists for this tree (setup.py
  # falls back to compiling), so we compile too. Pins from setup.py itself:
  # LLAMA_CPP_COMMIT and the repo the engine was built from here.
  strataSrc = fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "fb58e0dbc8399662c0e47c76578c6e878b14f6cf";
    hash = "sha256-WhoIwg8GgeG3jAXYLSjNoZyN3RZ3T3JhgJX57fM80eE=";
  };
  llamaSrc = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
  cudatoolkit = cudaPackages_13.cudatoolkit;
  pyEnv = python3Packages.python.withPackages (
    p: with p; [
      numpy
      jinja2
      regex
      pyyaml
      tqdm
      requests
      pillow
      psutil
    ]
  );
in
stdenv.mkDerivation {
  pname = "strata";
  version = "0.1.41-fb58e0d";

  src = strataSrc;

  nativeBuildInputs = [
    cmake
    ninja
    makeWrapper
  ];
  buildInputs = [ cudatoolkit ];

  # keithmoon's GPU: RTX 3060 (sm_86). The include fix mirrors the CPATH
  # workaround the imperative install needed: nixpkgs' split CUDA layout
  # leaves cuda_runtime.h off nvcc's host-preprocess path.
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DSTRATA_ENABLE_CUDA=ON"
    "-DSTRATA_BUILD_TESTS=OFF"
    "-DSTRATA_GGML_DIR=${llamaSrc}"
    "-DCMAKE_CUDA_ARCHITECTURES=86"
    "-DCMAKE_CUDA_COMPILER=${cudatoolkit}/bin/nvcc"
    "-DCUDAToolkit_ROOT=${cudatoolkit}"
  ];
  NVCC_PREPEND_FLAGS = "-I${cudatoolkit}/include";

  dontFixup = false;

  installPhase = ''
    runHook preInstall
    B=$(find "$NIX_BUILD_TOP" -maxdepth 3 -name strata -type f -perm -0100 | head -1)
    [ -n "$B" ] || { echo "strata binary not found"; exit 1; }
    install -Dm755 "$B" $out/bin/strata

    mkdir -p $out/share/strata
    cp -r ${strataSrc}/serve ${strataSrc}/tools ${strataSrc}/data $out/share/strata/
    cp -r ${llamaSrc}/gguf-py $out/share/strata/gguf-py
    # pack-prep tools resolve the repo root from their own path: keep a marker
    echo fb58e0dbc8399662c0e47c76578c6e878b14f6cf > $out/share/strata/REVISION

    makeWrapper ${pyEnv}/bin/python $out/bin/strata-server \
      --add-flags "$out/share/strata/serve/server.py" \
      --set STRATA_GGUF_PY $out/share/strata/gguf-py
    # bare interpreter with the pack-prep tools' env, for the systemd units
    makeWrapper ${pyEnv}/bin/python $out/bin/strata-python \
      --set STRATA_GGUF_PY $out/share/strata/gguf-py
    runHook postInstall
  '';

  meta = with lib; {
    description = "Strata: Qwen3.8-Flash-Next local LLM (engine + server)";
    homepage = "https://github.com/Niko1221/Strata";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
