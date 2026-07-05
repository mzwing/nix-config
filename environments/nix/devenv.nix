{pkgs, ...}: {
  languages.nix = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    alejandra
    just
    nixd
  ];

  enterTest = ''
    alejandra --version
    just --version
    nixd --version
  '';
}
