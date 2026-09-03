{
  mzwing.features."software/vscode" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      # The wakatime extension below only tracks once ~/.wakatime.cfg carries the key.
      "software/wakatime"
    ];

    darwin.homebrew.casks = ["visual-studio-code"];

    home = {
      lib,
      pkgs,
      ...
    }: let
      ext = import ../../../data/vscode/extensions.nix pkgs;
      settings = import ../../../data/vscode/settings.nix pkgs;

      core = with ext; base ++ git ++ remote ++ nixTools ++ shellTools;
      web = ext.webUi ++ ext.webJs;

      mkProfile = extensions: userSettings: {
        inherit extensions;
        userSettings = settings.core // userSettings;
        inherit (settings) keybindings;
        # programs.mcp comes from software/vibecoding; profiles do not inherit it, so every one asks for it.
        enableMcpIntegration = true;
      };

      profiles = {
        default = mkProfile core {};

        nodejs = mkProfile (core ++ web) settings.webJs;
        react = mkProfile (core ++ web ++ ext.react) settings.webJs;
        # No [vue] formatter override: oxfmt covers vue, so volar stays the language server and stops being the formatter.
        vue = mkProfile (core ++ web ++ ext.vue) settings.webJs;
        svelte = mkProfile (core ++ web ++ ext.svelte) (settings.webJs
          // {
            "svelte.enable-ts-plugin" = true;
          });
        lit = mkProfile (core ++ web ++ ext.lit) settings.webJs;
        solid = mkProfile (core ++ web ++ ext.solid) settings.webJs;
        bun = mkProfile (core ++ web ++ ext.bun) settings.webJs;
        # No webJs: deno's LSP takes over TypeScript and collides with eslint, oxc and tsgo.
        deno = mkProfile (core ++ ext.webUi ++ ext.deno) {};

        rust = mkProfile (core ++ ext.rust ++ ext.lldb ++ ext.tauri) {};
        c = mkProfile (core ++ ext.cpp ++ ext.lldb) {
          "cmake.configureOnOpen" = true;
        };
        go = mkProfile (core ++ ext.go) {
          "go.toolsManagement.autoUpdate" = true;
        };
        java = mkProfile (core ++ ext.java ++ ext.kotlin) {
          "[xml]"."editor.defaultFormatter" = "redhat.vscode-xml";
          "redhat.telemetry.enabled" = true;
        };
        python = mkProfile (core ++ ext.python ++ ext.jupyter) {
          "[python]"."editor.defaultFormatter" = "ms-python.black-formatter";
          "python.analysis.typeCheckingMode" = "strict";
        };
        ruby = mkProfile (core ++ ext.ruby) {};
        swift = mkProfile (core ++ ext.swift ++ ext.lldb) {};
        dart = mkProfile (core ++ ext.dart) {};
        zig = mkProfile (core ++ ext.zig) {};

        nix = mkProfile (core ++ ext.typenix) {
          "devenv.profile" = "";
        };
        shell = mkProfile (core ++ ext.ops) settings.ops;
        typst = mkProfile (core ++ ext.docs) {};
        ctf = mkProfile (core ++ ext.ctf) {};
      };
    in {
      programs =
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          vscode = {
            enable = true;
            package = null;
            inherit profiles;
          };
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          vscodium = {
            enable = true;
            package = pkgs.vscodium-fhs;
            inherit profiles;
          };
        };

      # VSCodium browses Open VSX by default; this points it at the marketplace the extensions above come from.
      # mkIf, not optionalAttrs: deciding this module's own attribute names from `pkgs` recurses through _module.args.
      xdg.configFile."VSCodium/product.json" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        source = (pkgs.formats.json {}).generate "vscodium-product.json" {
          extensionsGallery = {
            serviceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery";
            itemUrl = "https://marketplace.visualstudio.com/items";
            publisherUrl = "https://marketplace.visualstudio.com/publishers";
            extensionUrlTemplate = "https://www.vscode-unpkg.net/_gallery/{publisher}/{name}/latest";
            resourceUrlTemplate = "https://{publisher}.vscode-unpkg.net/{publisher}/{name}/{version}/{path}";
            controlUrl = "https://main.vscode-cdn.net/extensions/marketplace.json";
          };
        };
      };
    };
  };
}
