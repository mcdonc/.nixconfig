{pkgs, pkgs-unstable, ...}:

{
  environment.systemPackages = [
    pkgs.davinci-resolve-studio
    pkgs.davinci-resolve
  ];
}    

