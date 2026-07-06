{pkgs, ...}: {
  languages.python = {
    enable = true;

    venv.enable = true;

    uv = {
      enable = true;
      sync.enable = true;
    };

    lsp = {
      enable = true;
      package = pkgs.ty;
    };
  };

  enterTest = ''
    python --version | grep --color=auto "Python 3.12"
    uv --version
    command -v ty
  '';
}
