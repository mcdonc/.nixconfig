{ pkgs
, pkgs-py36
, pkgs-py37
, pkgs-py39
, inputs
, system
, ...
}:

let
  nixos-repl = pkgs.writeScriptBin "nixos-repl" ''
    #!/usr/bin/env ${pkgs.expect}/bin/expect

    set timeout 120
    spawn -noecho nix --extra-experimental-features repl nixpkgs
    expect "nix-repl> " {
      send ":a builtins\n"
      send "pkgs = legacyPackages.${system}\n"
      interact
    }
  '';

  findnixstorelinks = pkgs.writers.writePython3Bin "findnixstorelinks"
    {} (builtins.readFile ../../../bin/findnixstorelinks.py);

  python313WithPackages = (
    pkgs.python313.withPackages (p:
      with p; [
        pyflakes # for emacs
        flake8 # for emacs/vscode
        docutils # for vscode
        pygments # for vscode
        black # for cmdline and vscode
        tox
        build # for pypa build package
        twine # for uploading to PyPI
      ])
  );

  syspython = pkgs.writeScriptBin "syspython" ''
      exec ${python313WithPackages}/bin/python $@
  '';
in
{
  nixpkgs.config.permittedInsecurePackages = [
   "python-2.7.18.8"
  ]; # unmaintained python

  environment.systemPackages = with pkgs; [
    cachix
    vim-full
    wget
    openvpn
    unzip
    ripgrep
    btop
    killall
    # the order of python3s is intentional; python313 will be first the PATH
    python313WithPackages
    syspython
    pkgs-py36.python36
    pkgs-py37.python37
    pkgs-py39.python38
    pkgs-py39.python39
    python310
    python311
    python312
    pypy3
    python27
    xz
    ffmpeg-full
    iperf
    pciutils
    neofetch
    tmux
    s-tui
    stress-ng
    nmap
    nixfmt-rfc-style
    gptfdisk # "sgdisk"
    dig
    s3cmd
    rshell
    sqlite
    tldr
    tree
    lha
    nix-du
    graphviz
    bintools # "strings"
    cntr # for build debugging
    gnupg
    age
    lsof
    progress
    mc
    pre-commit
    html-tidy
    inetutils # for telnet
    file
    ruby
    nix-tree
    pv
    fio
    mbuffer
    gnumake
    bat
    nix-index # for nix-locate
    any-nix-shell
    speedtest-cli
    fast-cli
    nmap
    bottom
    openssl
    nixos-repl
    envsubst
    jq
    loccount
    zstd
    findnixstorelinks
    inotify-tools
    beep
    netcat
    util-linux # wipefs
    fd
    shellcheck
    inputs.isd.packages."${system}".default
    loccount
    go
    expect
    pbzip2
    dysk
    inputs.agenix.packages."${system}".default
    mailutils # for checking zed reports
    nil # for nix emacs lsp-mode
    rust-analyzer # for rust emacs lsp-mode
  ];
}
