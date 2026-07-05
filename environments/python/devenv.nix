{pkgs, ...}: {
  languages.python = {
    enable = true;
    version = "3.12";

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
