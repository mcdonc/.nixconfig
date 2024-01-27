{pkgs, ...}:

let

  myfile = pkgs.writeTextFile {
    name = "myfile";
    text = ''
       This is my file.
    '';
  };

in
  myfile

