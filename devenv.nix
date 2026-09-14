{
  inputs,
  pkgs,
  ...
}: {
  languages.nix = {
    enable = true;
    lsp.enable = true;
  };

  packages =
    (with pkgs; [
      act
      actionlint
      alejandra
      just
      nixd
      nixos-rebuild-ng
      ruff
      shellcheck
      shfmt
      ty
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ])
    ++ (with inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}; [
      typenix
    ]);

  cachix.pull = ["mzwing"];

  enterTest = ''
    act --version
    actionlint -version
    alejandra --version
    which agenix
    just --version
    nixd --version
    ruff --version
    shellcheck --version
    shfmt --version
    ty --version
    typenix --version
  '';
}
