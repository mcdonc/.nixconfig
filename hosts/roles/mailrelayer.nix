{ config, ... }:
{

  age.secrets."chris-mail-sasl" = {
    file = ../../secrets/chris-mail-sasl.age;
    mode = "600";
    owner = "postfix";
    group = "postfix";
  };

  services.postfix =
    let
      passwordfile = config.age.secrets."chris-mail-sasl".path;
    in
    {
      enable = true;
      settings.main = {
        relayhost = [ "[arctor.repoze.org]:587" ];
        myhostname = "${config.networking.hostName}.repoze.org";
        myorigin = "$myhostname";
        smtp_use_tls = "yes";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_security_options = "noanonymous";
        smtp_sasl_tls_security_options = "noanonymous";
        smtp_sasl_password_maps = "texthash:${passwordfile}";
        sender_canonical_maps = "regexp:/etc/postfix/canonical";
      };
      extraAliases = ''
        default: root
        root: chrism@repoze.org
      '';
      canonical = ''
        /^(.*[^@]+)@(${config.networking.hostName}|${config.networking.hostName}\.repoze\.org)$/    ''${1}@repoze.org
        /^(.*[^@]+)@([^.@]+(\.localdomain)?)$/        ''${1}@repoze.org
      '';
    };
}
