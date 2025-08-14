{ ... }:
{
  age.secrets."enfold-pat" = {
    file = ../../../secrets/enfold-pat.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-pydio-service-token" = {
    file = ../../../secrets/enfold-pydio-service-token.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-view-user-password" = {
    file = ../../../secrets/enfold-view-user-password.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-openai-api-key" = {
    file = ../../../secrets/enfold-openai-api-key.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-pydio-realm-pem" = {
    file = ../../../secrets/enfold-pydio-realm-pem.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-slack-notify-url" = {
    file = ../../../secrets/enfold-slack-notify-url.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."mcdonc-cachix-authtoken" = {
    file = ../../../secrets/mcdonc-cachix-authtoken.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-cachix-authtoken" = {
    file = ../../../secrets/enfold-cachix-authtoken.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

  age.secrets."enfold-ngpt" = {
    file = ../../../secrets/enfold-ngpt.age;
    mode = "640";
    owner = "root";
    group = "users";
  };

}
