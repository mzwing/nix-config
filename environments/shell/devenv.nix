{pkgs, ...}: {
  languages.shell = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    shfmt
  ];

  enterTest = ''
    bash-language-server --version
    shfmt --version
  '';
}
