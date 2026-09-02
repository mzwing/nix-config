pkgs: let
  inherit (pkgs) lib;

  # Everything oxfmt handles, taken from the extension's own activation events. The JS-family profiles hand it all of them,
  # which deliberately outranks the core [yaml] entry and the toml/scss formatters those profiles also carry.
  oxcLanguages = [
    "astro"
    "css"
    "graphql"
    "handlebars"
    "html"
    "javascript"
    "javascriptreact"
    "json"
    "json5"
    "jsonc"
    "less"
    "markdown"
    "mdx"
    "mjml"
    "scss"
    "svelte"
    "toml"
    "typescript"
    "typescriptreact"
    "vue"
    "yaml"
  ];
in {
  core =
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
      # "off", not false: the boolean is the legacy spelling and VSCode rewrites it on launch, which a store symlink refuses.
      "extensions.autoUpdate" = "off";
      "extensions.autoCheckUpdates" = false;

      "diffEditor.codeLens" = true;
      "http.systemCertificatesNode" = true;

      "chat.sessionSync.enabled" = true;
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

  keybindings = map (key: {
    inherit key;
    command = "workbench.action.terminal.sendSequence";
    when = "terminalFocus";
    args.text = "\\\r\n";
  }) ["ctrl+enter" "shift+enter"];

  webJs =
    lib.genAttrs (map (l: "[${l}]") oxcLanguages) (_: {
      "editor.defaultFormatter" = "oxc.oxc-vscode";
    })
    // {
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "js/ts.experimental.useTsgo" = true;
      "vite.autoStart" = false;
      "vite.browserType" = "system";
    };

  ops = {
    "nginx-conf-hint.syntax" = "sublime";
  };
}
