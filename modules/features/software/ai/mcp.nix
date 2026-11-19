{
  mzwing.features."software/ai/mcp" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.home = pkgs: [pkgs.nur.repos.mzwing.codegraph];

    home = {
      lib,
      pkgs,
      ...
    }: {
      programs.mcp = {
        enable = true;
        servers = {
          # ace-ctx = {
          #   command = lib.getExe pkgs.nur.repos.mzwing.ace-ctx;
          #   env = {
          #     ACE_BASE_URL = "http://localhost:8999";
          #     ACE_TOKEN = "sk-1145141919810";
          #   };
          # };
          codegraph = {
            command = lib.getExe pkgs.nur.repos.mzwing.codegraph;
            args = [
              "serve"
              "--mcp"
            ];
            env = {
              CODEGRAPH_TELEMETRY = "0";
              CODEGRAPH_NO_UPDATE_CHECK = "1";
            };
          };
          colab-mcp = {
            command = lib.getExe' pkgs.uv "uvx";
            args = [
              "--from"
              "git+https://github.com/googlecolab/colab-mcp@v1.0.2"
              "colab-mcp"
            ];
            env = {
              UV_PYTHON = lib.getExe pkgs.python313;
              UV_PYTHON_DOWNLOADS = "never";
            };
            timeout = 30000;
          };
        };
      };
    };
  };
}
