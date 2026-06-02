{ pkgs, pkgs-unstable, inputs, system, config, lib, ... }:

let
  # ── whisper model ──────────────────────────────────────────────
  # base.en is ~142 MB – good balance of speed and accuracy for English.
  # Other options: tiny.en (~74 MB, faster), small.en (~466 MB, more accurate).
  whisperModelName = "base.en";

  # herdr binary (from flake input or nixpkgs)
  herdrBin = "${inputs.herdr.packages.${system}.default}/bin/herdr";

  # ── the main voice→pi script ───────────────────────────────────
  voice-pi = pkgs.writeShellScriptBin "voice-pi" ''
    set -euo pipefail

    AUTO_DURATION=""
    if [ "''${1:-}" = "--auto" ]; then
      AUTO_DURATION="''${2:-8}"
    fi

    MODEL_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/voice-pi"
    MODEL="$MODEL_DIR/ggml-${whisperModelName}.bin"
    WORK_DIR="''${XDG_RUNTIME_DIR:-/tmp}/voice-pi"
    mkdir -p "$MODEL_DIR" "$WORK_DIR"

    # ── download model if missing ──────────────────────────────
    if [ ! -f "$MODEL" ]; then
      echo "→ Downloading whisper model (one-time) …" >&2
      ${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model \
        ${whisperModelName} "$MODEL_DIR"
      echo "✓ Model ready" >&2
    fi

    # ── record ─────────────────────────────────────────────────
    RAW="$WORK_DIR/recording.wav"
    NORMED="$WORK_DIR/normed.wav"

    if [ -n "$AUTO_DURATION" ]; then
      echo "🎤  Recording for ''${AUTO_DURATION}s …" >&2
      ${pkgs.alsa-utils}/bin/arecord \
        -f cd -t wav -q -d "$AUTO_DURATION" "$RAW"
    else
      echo "🎤  Recording …  press Enter to stop" >&2
      ${pkgs.alsa-utils}/bin/arecord \
        -f cd -t wav -q "$RAW" &
      RECORD_PID=$!
      read -r _
      kill "$RECORD_PID" 2>/dev/null || true
      wait "$RECORD_PID" 2>/dev/null || true
    fi

    # ── check we actually recorded something ───────────────────
    if [ ! -s "$RAW" ]; then
      echo "✗  No audio captured (is your mic connected?)" >&2
      exit 1
    fi

    # ── normalise volume ───────────────────────────────────────
    ${pkgs.sox}/bin/sox "$RAW" -b 16 -r 16000 "$NORMED" \
      norm -0.1 silence 1 0.1 0.5% reverse silence 1 0.1 0.5% reverse

    # ── transcribe ─────────────────────────────────────────────
    echo "→ Transcribing …" >&2
    TEXT=$(${pkgs.whisper-cpp}/bin/whisper-cli \
      -m "$MODEL" \
      -f "$NORMED" \
      --no-timestamps \
      --language en \
      -np 2>/dev/null)

    if [ -z "$TEXT" ]; then
      echo "✗  No speech detected" >&2
      exit 1
    fi

    # ── show what we heard ─────────────────────────────────────
    echo ""
    echo "📝  $TEXT"
    echo ""

    # ── send to herdr ───────────────────────────────────────────
    # When invoked as a herdr custom command, HERDR_ACTIVE_PANE_ID
    # points to the pane that had focus when the keybinding fired.
    # Otherwise, scan for the currently focused pane.
    HERDR="${herdrBin}"
    if [ -x "$HERDR" ]; then
      PANE="''${HERDR_ACTIVE_PANE_ID:-}"
      if [ -z "$PANE" ]; then
        PANE=$("$HERDR" pane list --json 2>/dev/null \
          | ${pkgs.jq}/bin/jq -r 'first(.. | objects | select(.focused == true) | .pane_id) // empty')
      fi
      if [ -n "$PANE" ]; then
        "$HERDR" pane run "$PANE" "$TEXT" \
          && echo "✓  Sent to herdr pane $PANE" >&2 \
          && exit 0
      fi
    fi

    # ── fallback: print to stdout ────────────────────────────────
    echo "→ Herdr not detected — printing to stdout:" >&2
    echo "$TEXT"
  '';

  # ── quick transcription-only helper (no pi integration) ──────
  voice-transcribe = pkgs.writeShellScriptBin "voice-transcribe" ''
    set -euo pipefail

    MODEL_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/voice-pi"
    MODEL="$MODEL_DIR/ggml-${whisperModelName}.bin"
    WORK_DIR="''${XDG_RUNTIME_DIR:-/tmp}/voice-pi"
    mkdir -p "$MODEL_DIR" "$WORK_DIR"

    if [ ! -f "$MODEL" ]; then
      echo "→ Downloading whisper model …" >&2
      ${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model \
        ${whisperModelName} "$MODEL_DIR"
    fi

    RAW="$WORK_DIR/transcribe.wav"
    NORMED="$WORK_DIR/transcribe-normed.wav"

    echo "🎤  Recording …  Ctrl-C to stop" >&2
    ${pkgs.alsa-utils}/bin/arecord \
      -f cd -t wav -q "$RAW" &
    RECORD_PID=$!

    trap 'kill $RECORD_PID 2>/dev/null; wait $RECORD_PID 2>/dev/null; exit 0' INT TERM
    wait "$RECORD_PID" 2>/dev/null || true

    if [ ! -s "$RAW" ]; then
      echo "✗  No audio" >&2
      exit 1
    fi

    ${pkgs.sox}/bin/sox "$RAW" -b 16 -r 16000 "$NORMED" \
      norm -0.1 silence 1 0.1 0.5% reverse silence 1 0.1 0.5% reverse

    echo "→ Transcribing …" >&2
    ${pkgs.whisper-cpp}/bin/whisper-cli \
      -m "$MODEL" \
      -f "$NORMED" \
      --no-timestamps \
      --language en \
      -np
  '';
in
{
  # ── packages ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    inputs.herdr.packages."${system}".default
    voice-pi
    voice-transcribe
    whisper-cpp
    sox
    jq
    gawk
  ];

  # ── pre-download model at build time (optional 142 MB) ─────────
  # Uncomment to bake the model into /nix/store so no per-user
  # download is needed.  Adjust the model name and hash accordingly.
  #
  # environment.etc."voice-pi/ggml-${whisperModelName}.bin".source =
  #   pkgs.fetchurl {
  #     url =
  #       "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/"
  #       + "ggml-${whisperModelName}.bin";
  #     hash = "";  # build once, paste the hash from the error msg
  #   };
}
