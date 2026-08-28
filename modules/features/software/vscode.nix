{
  mzwing.features."software/vscode" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = ["visual-studio-code"];
    };

    home = {
      config,
      lib,
      pkgs,
      ...
    }: let
      ext = import ../../../data/vscode/extensions.nix pkgs;

      # Every profile starts here: reading an unfamiliar repository needs none of the language groups.
      core = with ext; base ++ git ++ remote ++ nixTools ++ shellTools;

      web = ext.webUi ++ ext.webJs;

      coreSettings =
        {
          "security.workspace.trust.untrustedFiles" = "open";

          "editor.tabSize" = 2;
          "editor.wordWrap" = "on";
          "editor.fontSize" = 13;
          "editor.fontFamily" = "'JetBrains Mono', Menlo, Monaco, 'Courier New', monospace";
          "editor.codeLensFontFamily" = "'JetBrains Mono'";
          "editor.gotoLocation.multipleDefinitions" = "goto";

          "files.autoSave" = "onFocusChange";
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;

          "workbench.startupEditor" = "none";
          "workbench.colorTheme" = "Dark Modern";
          "workbench.browser.openLocalhostLinks" = false;

          "update.showReleaseNotes" = false;
          # The extensions directory is a read-only store symlink, so any update attempt can only fail.
          "extensions.autoUpdate" = false;
          "extensions.autoCheckUpdates" = false;

          "diffEditor.codeLens" = true;
          "http.systemCertificatesNode" = true;

          "chat.viewSessions.orientation" = "stacked";
          "chat.tools.terminal.autoApprove" = {
            "/^sips -s format png ref\\.pdf --out ref\\.png$/" = {
              approve = true;
              matchCommandLine = true;
            };
          };

          "github.copilot.nextEditSuggestions.enabled" = true;
          "github.copilot.nextEditSuggestions.eagerness" = "low";
          "github.copilot.enable" = {
            "*" = true;
            ini = true;
            "java-properties" = false;
            markdown = true;
            plaintext = true;
            scminput = false;
            shellscript = true;
            typst = false;
          };
          "claudeCode.preferredLocation" = "panel";

          "json.schemaDownload.trustedDomains" = {
            "https://schemastore.azurewebsites.net/" = true;
            "https://raw.githubusercontent.com/" = true;
            "https://www.schemastore.org/" = true;
            "https://json.schemastore.org/" = true;
            "https://json-schema.org/" = true;
            "https://opencode.ai/config.json" = true;
            "https://models.dev/model-schema.json" = true;
            "https://unpkg.com" = true;
          };

          "yaml.disableSchemaDetection" = [
            "**/.github/workflows/*.yml"
            "**/.github/workflows/*.yaml"
            "**/.gitea/workflows/*.yml"
            "**/.gitea/workflows/*.yaml"
            "**/.forgejo/workflows/*.yml"
            "**/.forgejo/workflows/*.yaml"
          ];
          "[yaml]"."editor.defaultFormatter" = "redhat.vscode-yaml";

          "todo-tree.ripgrep.ripgrep" = lib.getExe pkgs.ripgrep;

          "git.confirmSync" = false;
          "git.autofetch" = true;
          "git.enableSmartCommit" = true;
          "git.enableCommitSigning" = true;
          "git.replaceTagsWhenPull" = true;
          "git-graph.repository.commits.showSignatureStatus" = true;
          "git-graph.repository.sign.commits" = true;
          "git-graph.repository.sign.tags" = true;

          "remoteHub.commitDirectlyWarning" = "off";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          "terminal.external.osxExec" = "Ghostty.app";
          "terminal.integrated.defaultProfile.osx" = "fish";
        };

      coreKeybindings = map (key: {
        inherit key;
        command = "workbench.action.terminal.sendSequence";
        when = "terminalFocus";
        args.text = "\\\r\n";
      }) ["ctrl+enter" "shift+enter"];

      webJsSettings = {
        "[typescript]"."editor.defaultFormatter" = "TypeScriptTeam.native-preview";
        "[javascript]"."editor.defaultFormatter" = "TypeScriptTeam.native-preview";
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "js/ts.experimental.useTsgo" = true;
        "vite.autoStart" = false;
        "vite.browserType" = "system";
      };

      opsSettings =
        {
          "nginx-conf-hint.syntax" = "sublime";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          "parallels-desktop.extension.path" = "${config.home.homeDirectory}/.parallels-desktop-vscode";
          "parallels-desktop.devops-service.path" = "${config.home.homeDirectory}/.parallels-desktop-vscode/tools/prldevops";
          "parallels-desktop.brew.path" = "/opt/homebrew/bin/brew";
          "parallels-desktop.prlctl.path" = "/usr/local/bin/prlctl";
          "parallels-desktop.git.path" = lib.getExe pkgs.git;
        };

      mkProfile = extensions: userSettings: {
        inherit extensions;
        userSettings = coreSettings // userSettings;
        keybindings = coreKeybindings;
        # programs.mcp comes from software/vibecoding; profiles do not inherit it, so every one asks for it.
        enableMcpIntegration = true;
      };

      profiles = {
        default = mkProfile core {};

        nodejs = mkProfile (core ++ web ++ ext.solid) webJsSettings;
        react = mkProfile (core ++ web ++ ext.react) webJsSettings;
        vue = mkProfile (core ++ web ++ ext.vue) (webJsSettings
          // {
            "[vue]"."editor.defaultFormatter" = "Vue.volar";
          });
        svelte = mkProfile (core ++ web ++ ext.svelte) (webJsSettings
          // {
            "svelte.enable-ts-plugin" = true;
          });
        lit = mkProfile (core ++ web ++ ext.lit) webJsSettings;
        bun = mkProfile (core ++ web ++ ext.bun) webJsSettings;
        # No webJs: deno's LSP takes over TypeScript and collides with eslint, oxc and tsgo.
        deno = mkProfile (core ++ ext.webUi ++ ext.deno) {};

        rust = mkProfile (core ++ ext.rust ++ ext.lldb ++ ext.tauri) {};
        c = mkProfile (core ++ ext.cpp ++ ext.lldb) {
          "cmake.configureOnOpen" = true;
        };
        go = mkProfile (core ++ ext.go) {
          "go.toolsManagement.autoUpdate" = true;
        };
        # Kotlin rides along: it shares the Gradle tooling and never appears without a JVM around.
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
        shell = mkProfile (core ++ ext.ops) opsSettings;
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
      # Values read off an official VS Code build's resources/app/product.json.
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
