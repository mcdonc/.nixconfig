{ pkgs, pkgs-unstable, ... }:

{
  services.ollama.enable = true;
  services.ollama.package = pkgs-unstable.ollama-cuda;
  services.ollama.acceleration = "cuda";
  services.ollama.loadModels = [
    "codellama:7b"
    "qwen2.5-coder:7b"
  ];
  services.ollama.environmentVariables = {
    "OLLAMA_CONTEXT_LENGTH" = "64000";
  };

  services.open-webui.enable = true;
  services.open-webui.package = pkgs-unstable.open-webui;

  nix.settings = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
