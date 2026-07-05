{...}: {
  languages.ruby = {
    enable = true;
    bundler.enable = true;
    documentation.enable = true;
    lsp.enable = true;
  };

  enterTest = ''
    ruby --version
    bundle --version
  '';
}
