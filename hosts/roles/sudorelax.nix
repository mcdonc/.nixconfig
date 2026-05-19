{ ... }:

{
  security.sudo.extraRules = [{
    users = [ "chrism" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
