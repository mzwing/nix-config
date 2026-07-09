{
  inputs,
  pkgs,
  ...
}: {
  languages.nix = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    alejandra
    just
    nixd
    inputs.typenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  enterTest = ''
    alejandra --version
    just --version
    nixd --version
    typenix --version
  '';
}
