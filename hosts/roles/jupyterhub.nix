{ ... }:
{
  
  services.jupyterhub.enable = true;
  services.jupyterhub.extraConfig = ''
    c.Authenticator.allow_all = True # all who have a local account
    c.ConfigurableHTTPProxy.api_url = 'http://127.0.0.1:8010'
  '';
}

