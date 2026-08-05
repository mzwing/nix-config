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
    act
    actionlint
    alejandra
    just
    nixd
    nixos-rebuild-ng
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    nur.repos.mzwing.typenix
  ];

  enterTest = ''
    act --version
    actionlint -version
    alejandra --version
    which agenix
    just --version
    nixd --version
    typenix --version
  '';
}
