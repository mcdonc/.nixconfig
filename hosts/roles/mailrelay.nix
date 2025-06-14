{ config, ... }:
{

  age.secrets."chris-mail-sasl" = {
    file = ../../secrets/chris-mail-sasl.age;
    mode = "600";
  };

  services.postfix =
    let
      passwordfile = config.age.secrets."chris-mail-sasl".path;
    in
      {
        enable = true;
        relayHost = "arctor.repoze.org";
        relayPort = 587;
        config = {
          smtp_use_tls = "yes";
          smtp_sasl_auth_enable = "yes";
          smtp_sasl_security_options = "";
          smtp_sasl_password_maps = "texthash:${passwordfile}";
          # Forward mails to root (e.g. from cron jobs, smartd, etc)
          virtual_alias_maps = "inline:{ {root=chrism@repoze.org } }";
        };
      };
}
