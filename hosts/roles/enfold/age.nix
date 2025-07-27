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


}

  
