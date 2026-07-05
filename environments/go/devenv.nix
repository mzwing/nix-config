{...}: {
  languages.go = {
    enable = true;
    enableHardeningWorkaround = true;
    delve.enable = true;
    lsp.enable = true;
  };

  enterTest = ''
    go version
    dlv version
    gopls version
  '';
}
