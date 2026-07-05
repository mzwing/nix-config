{pkgs, ...}: {
  languages.typst = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    typstyle
  ];

  enterTest = ''
    typst --version
    tinymist --version
    typstyle --version
  '';
}
