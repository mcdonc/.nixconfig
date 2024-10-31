{pkgs, ...}:

{
  environment.systemPackages = [

    (
      pkgs.buildGo123Module rec {
        pname ="amazon-ec2-instance-selector";
        version = "3.0.0";
        src = pkgs.fetchFromGitHub {
          owner = "aws";
          repo = "amazon-ec2-instance-selector";
          rev = "v${version}";
          sha256="sha256-NQoBGl1EX678gpwmsxXfLg95KdhVd31j1geBs4zzMjc=";
        };
        vendorHash = "sha256-IHNJaE72hofc5cRXL69+i2CBhFL9LD8w4ix5bjomTiE=";
        
      }
    )
  ];
}
