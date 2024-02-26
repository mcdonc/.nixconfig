
{
  nix = {
    settings.substituters = [
      "https://mcdonc-embedded.cachix.org"
    ];
    settings.trusted-public-keys = [
      "mcdonc-embedded.cachix.org-1:f6WMfW/n/dgZ4Gs+jjw5gWOneJREkeQZdZOQHnjTw0w="
    ];
  };
}
