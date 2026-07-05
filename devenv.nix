{pkgs, ...}: {
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
