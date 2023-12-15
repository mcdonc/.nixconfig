{ pkgs, ... }:

{
  # https://devenv.sh/reference/options/
  packages = [
    pkgs.python311Packages.psycopg2
  ]; # XXX pkgs?
  
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "mydb"; }];
    settings = {
      unix_socket_directories = "/tmp";
    };
  };
  
  languages.python = {
    enable = true;
    # version = "3.11.3";
    venv = {
      enable = true;
      quiet = true;
    };
  };
  
  enterShell = ''pip install -e $DEVENV_ROOT'';
  
  processes.myapp.exec = "pserve $DEVENV_ROOT/development.ini";
}
  
