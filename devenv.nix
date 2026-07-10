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
    nixos-rebuild-ng
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.typenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  enterTest = ''
    alejandra --version
    agenix --version
    just --version
    nixd --version
    typenix --version
  '';
}
