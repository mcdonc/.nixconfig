# Strata — Qwen3.8-Flash-Next IQ2_XS local LLM server, fully declarative.
#
# What is in the store (pkgs/strata.nix): the CUDA engine (compiled from the
# pinned Strata + llama.cpp sources) and the python server + prep tools.
# What is NOT in the store (too big, ~75 GB, changes rarely): the model GGUF
# shards, the prepared expert pack and the MTP draft layer. Those live in
# /var/lib/strata, managed by idempotent systemd units:
#
#   strata-fetch.service    downloads the two IQ2_XS shards from Hugging
#                           Face at the commit setup.py pins (resumable)
#   strata-prepare.service  builds packs/iq2_xs (iq_pack.py), downloads and
#                           packs the MTP draft layer (speculative decoding)
#   strata.service          strata-server --engine strata (127.0.0.1:8080)
#
# First boot: fetch (~72 GB) -> prepare (~10 min) -> server. Later boots:
# everything is guarded and starts straight away.
#
# Engine args mirror what setup.py generates for this exact hardware
# (single RTX 3060 sm_86, 126 GB RAM, 64K context, int8 KV, no vision):
# kv-resident 32768 (ctx >= 64K: the ~0.9 GB streamed KV fits beside the
# 48 GB of experts in RAM), no pool-workers (uniform Xeon), no rope scaling
# (64K is within the trained 262144). Verified against the pinned setup.py:
# kv_streaming_wanted('IQ2_XS', 65536, 'int8', 126) = True,
# resolve_rope(65536, None, None) = (None, None).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  strata = pkgs.callPackage ../../pkgs/strata.nix { };

  dataDir = "/var/lib/strata";
  modelDir = "${dataDir}/models";
  packDir = "${dataDir}/packs/iq2_xs";
  mtpDir = "${dataDir}/mtp";

  hf = "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF";
  # the commit setup.py pins for this repository (SOURCE_PINS); files live
  # under a per-size subdirectory ({q}/ in the family URL template)
  rev = "ed59f92082b1e93c0e96d60a8b11aab089b52f09";
  sizeDir = "IQ2_XS";
  shard1 = "Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00001-of-00002.gguf";
  shard2 = "Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00002-of-00002.gguf";

  runConfig = pkgs.writeText "strata-iq2_xs.json" (builtins.toJSON {
    exe = "${strata}/bin/strata";
    args = [
      "--pack" packDir
      "--native" "${modelDir}/${shard1}"
      "--ple-gguf" "${modelDir}/${shard2}"
      "--expert-profile" "${strata}/share/strata/data/expert-profile.bin"
      "--expert-cache" "auto"
      "--prefill" "auto"
      "--spec" "4"
      "--spec-min-p" "0.5"
      "--mtp" "${mtpDir}/rt"
      "--max-context" "65536"
      "--kv-resident" "32768"
      "--kv" "int8"
    ];
    cwd = dataDir;
    tokenizer = "${packDir}/tokenizer";
    model_name = "qwen3.8-flash-next-iq2_xs";
    log = "${dataDir}/strata-iq2_xs.log";
    port = 8080;
  });

  py = "${strata}/bin/strata-python";
  tools = "${strata}/share/strata/tools";
in
{
  options.services.strata = {
    enable = lib.mkEnableOption "Strata local LLM server (Qwen3.8-Flash-Next IQ2_XS) on 127.0.0.1:8080";
  };

  config = lib.mkIf config.services.strata.enable {
    users.users.strata = {
      isSystemUser = true;
      group = "strata";
      home = dataDir;
      # NVIDIA device nodes
      extraGroups = [
        "video"
        "render"
      ];
    };
    users.groups.strata = { };

    systemd.services.strata-fetch = {
      description = "Strata model download (IQ2_XS shards from Hugging Face)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "strata-prepare.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "strata";
        StateDirectory = "strata";
        RemainAfterExit = true;
      };
      # resumable: curl -C - skips completed files
      script = ''
        install -d -m 755 ${modelDir}
        for f in ${shard1} ${shard2}; do
          ${lib.getExe pkgs.curl} -L -C - --fail -o "${modelDir}/$f.part" \
            "${hf}/resolve/${rev}/${sizeDir}/$f"
          mv "${modelDir}/$f.part" "${modelDir}/$f"
        done
      '';
    };

    systemd.services.strata-prepare = {
      description = "Strata model preparation (expert pack + MTP draft layer)";
      requires = [ "strata-fetch.service" ];
      after = [ "strata-fetch.service" ];
      before = [ "strata.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "strata";
        StateDirectory = "strata";
        RemainAfterExit = true;
      };
      script = ''
        set -e
        # expert pack + tokenizer (idempotent: iq_pack skips a finished pack)
        ${py} ${tools}/iq_pack.py --gguf ${modelDir}/${shard1} --out ${packDir}
        # MTP draft layer: ~5 GB from the original checkpoint, then packed
        ${py} ${tools}/mtp_fetch.py fetch --out ${mtpDir}
        ${py} ${tools}/mtp_pack.py --src ${mtpDir} --experts q2_0 --out ${mtpDir}/mtp-q2_0.gguf
        ${py} ${tools}/mtp_rt.py --gguf ${mtpDir}/mtp-q2_0.gguf --out ${mtpDir}/rt
        # the default (cjk) draft vocabulary
        cp -f ${strata}/share/strata/data/draft_vocab.bin ${mtpDir}/rt/draft_vocab.bin
      '';
    };

    systemd.services.strata = {
      description = "Strata local LLM server (Qwen3.8-Flash-Next IQ2_XS)";
      documentation = [ "http://127.0.0.1:8080/" ];
      requires = [ "strata-prepare.service" ];
      after = [ "strata-prepare.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "strata";
        StateDirectory = "strata";
        ExecStart = "${strata}/bin/strata-server --engine strata --config ${runConfig} --port 8080";
        LimitMEMLOCK = "infinity";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
