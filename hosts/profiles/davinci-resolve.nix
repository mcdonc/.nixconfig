{pkgs, pkgs-unstable, ...}:

{
  environment.systemPackages = [
    pkgs-unstable.davinci-resolve-studio
    pkgs-unstable.davinci-resolve
  ];
}    

