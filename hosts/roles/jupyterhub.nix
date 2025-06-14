{ ... }:
{
  
  services.jupyterhub.enable = true;
  services.jupyterhub.extraConfig = ''
   c.Authenticator.allow_all = True
  '';
}

