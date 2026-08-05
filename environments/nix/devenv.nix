{
  inputs,
  pkgs,
  ...
}: {
  overlays = [inputs.nur.overlays.default];

  languages.nix = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    alejandra
    just
    nixd
    nur.repos.mzwing.typenix
  ];

  enterTest = ''
    alejandra --version
    just --version
    nixd --version
    typenix --version
  '';
}
