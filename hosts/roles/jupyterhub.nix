{ ... }:
{
  
  services.jupyterhub.enable = true;
  services.jupyterhub.extraConfig = ''
    c.Authenticator.allowed_users = {"chrism", "tseaver"}
    c.ConfigurableHTTPProxy.api_url = 'http://127.0.0.1:8010'
  '';
}

