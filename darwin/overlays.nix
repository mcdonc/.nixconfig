self: super:

let
  # Define the older version of Emacs you want to use
  emacsOlderVersion = super.emacs.overrideAttrs (oldAttrs: {
    version = "29.4";
    src = super.fetchurl {
      url = "https://ftp.gnu.org/gnu/emacs/emacs-29.4.tar.gz";
      sha256 = "";
    };
  });
in
{
  emacs = emacsOlderVersion;
}
