{...}: {
  languages.zig = {
    enable = true;
    lsp.enable = true;
  };

  enterTest = ''
    zig version
    zls --version
  '';
}
