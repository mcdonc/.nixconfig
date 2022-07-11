https://discourse.nixos.org/t/what-does-mkdefault-do-exactly/9028

mkOptionDefault = mkOverride 1500
mkDefault = mkOverride 1000
mkForce = mkOverride 50

Things not run through a mk... function:  mkOverride 100

How are modules merged?

https://github.com/NixOS/nixpkgs/blob/9dfcba812aa0f4dc374acfe0600d591885f4e274/lib/modules.nix#L646

