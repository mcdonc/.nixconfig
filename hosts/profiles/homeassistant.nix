{...}:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
      # mcdonc-added
      "cast"
      "denonavr"
      "spotify"
      "harmony"
      "eufylife_ble"
      "ipp"
      "ibeacon"
      "led_ble"
      "heos"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
    };
  };
}
