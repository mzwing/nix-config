{pkgs, ...}: {
  languages.rust = {
    enable = true;
    channel = "nightly";
    lsp.enable = true;
    cranelift.enable = true;
    # on NixOS, uncomment the following line
    # cranelift.enable = true;
    # wild.enable = true;
  };

  git-hooks.hooks = {
    rustfmt.enable = true;
    clippy.enable = true;
  };

  packages = [
    pkgs.crate2nix
  ];

  enterTest = ''
    rust --version
    cargo --version
    crate2nix --version
    rustfmt --version
    clippy-driver --version
    rust-analyzer --version
  '';
}
