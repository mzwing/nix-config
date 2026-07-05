{pkgs, ...}: {
  languages.rust = {
    enable = true;
    channel = "nightly";
    lsp.enable = true;
    cranelift.enable = true;
    mold.enable = true; # On MacOS, use this
    # wild.enable = true; # On NixOS, use this
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
