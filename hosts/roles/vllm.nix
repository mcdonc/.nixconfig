{ ... }:

{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.vllm = {
    image = "vllm/vllm-openai:latest";
    extraOptions = [
      "--gpus"
      "all"
      "--shm-size"
      "8g"
    ];
    ports = [ "11435:8000" ];
    cmd = [
      "--model"
      "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ"
      "--max-model-len"
      "16384"
      "--gpu-memory-utilization"
      "0.75"
      "--enable-auto-tool-choice"
      "--tool-call-parser"
      "hermes"
      # "--tensor-parallel-size" "1"
    ];
    # volumes = [
    #   "/path/to/huggingface/cache:/root/.cache/huggingface"
    # ];
    # environment = {
    #   HUGGING_FACE_HUB_TOKEN = "your-token";  # for gated models like Llama
    # };
  };
}
