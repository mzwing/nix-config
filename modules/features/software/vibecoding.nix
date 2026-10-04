{
  mzwing.features."software/vibecoding" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "software/claude-code"
      "software/cliproxyapiplus"
      "software/omp"
      "software/paseo"
      "software/pi-coding-agent"
      "software/skills"
    ];

    packages = {
      nixos = pkgs: [pkgs.antigravity];
      home = pkgs: [pkgs.nur.repos.mzwing.codegraph];
    };

    darwin.homebrew.casks = [
      "antigravity"
      "chatgpt"
    ];

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
        };
      };
    };
  };
}
