{ pkgs ? import <nixpkgs> { } }:
let
  pyedid = with pkgs.python3Packages;
    buildPythonPackage rec {
      pname = "pyedid";
      version = "1.0.1";

      src = fetchPypi {
        inherit pname version;
        sha256 = "sha256-gFGjPtPfTTuFzzAQhrOHvYqem+G5OXTUun17Wu75f54=";
      };

      propagatedBuildInputs = [ requests ];

      doCheck = false;

      meta = with pkgs.lib; {
        homepage = "https://github.com/dd4e/pyedid";
        description = "Python EDID parser library";
        license = licenses.mit;
        #maintainers = with maintainers; [ fridh ];
      };
    };
in pkgs.mkShell { buildInputs = [ pyedid ]; }
