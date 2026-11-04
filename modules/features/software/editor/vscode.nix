{
  mzwing.features."software/editor/vscode" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "software/development/wakatime"
    ];

    darwin.homebrew.casks = ["visual-studio-code"];

    home = {
      config,
      lib,
      pkgs,
      ...
    }: let
      ext = import ../../../../data/vscode/extensions.nix pkgs;
      settings = import ../../../../data/vscode/settings.nix pkgs;

      core = with ext; base ++ git ++ remote ++ nixTools ++ shellTools;
      web = ext.webUi ++ ext.webJs;

      signs = config.programs.git.signing.signByDefault;

      mkProfile = extensions: userSettings: {
        inherit extensions;
        userSettings =
          settings.core
          // {
            "git.enableCommitSigning" = signs;
            "git-graph.repository.sign.commits" = signs;
            "git-graph.repository.sign.tags" = signs;
          }
          // userSettings;
        inherit (settings) keybindings;
        # programs.mcp comes from software/ai/mcp; profiles do not inherit it, so every one asks for it.
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
        java = mkProfile (core ++ ext.java) {
          "[xml]"."editor.defaultFormatter" = "redhat.vscode-xml";
          "redhat.telemetry.enabled" = true;
          # intellij-server's setup wizard saves these to user settings, which a store symlink refuses
          "intellij.region" = "apac";
          "intellij.dataSharing" = "none";
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
          "[nix]"."editor.defaultFormatter" = "ryanrasti.typenix";
          "devenv.profile" = "";
        };
        shell = mkProfile (core ++ ext.ops) settings.ops;
        typst = mkProfile (core ++ ext.docs) {};
        ctf = mkProfile (core ++ ext.ctf) {};
      };

      intellijServerExtension = lib.findFirst (e: e.vscodeExtUniqueId == "jetbrains.intellij-server") null ext.java;
      intellijServerRoot = "${
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${config.home.homeDirectory}/Library/Application Support"
        else config.xdg.dataHome
      }/JetBrains/IntelliJServer/servers/intellij-server";
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

      # The extension keeps every server build it ever pinned, about 1.3 GB each
      home.activation.pruneOldIntellijServers = lib.hm.dag.entryAfter ["writeBoundary"] ''
        (
          shopt -s nullglob
          root=${lib.escapeShellArg intellijServerRoot}
          current=$(jq -r .version ${intellijServerExtension}/share/vscode/extensions/${intellijServerExtension.vscodeExtUniqueId}/server-bundle.json)
          for entry in "$root"/* "$root"/server-downloads/*; do
            case ''${entry##*/} in
              "$current" | "$current.lock" | server-downloads) ;;
              *) run rm -rf "$entry" ;;
            esac
          done
        )
      '';
    };
  };
}
