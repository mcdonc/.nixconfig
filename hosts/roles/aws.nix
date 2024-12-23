{ pkgs, ...}:

{
  environment.systemPackages = [
    pkgs.awscli
  ];
}
  
