{lib, ...}: let
  extensions = lib.importJSON ../../../../data/chromium/extensions.json;

  policies = {
    # Chromium itself uninstalls every extension the list doesn't name, however it got installed.
    ExtensionSettings =
      lib.mapAttrs' (_: id: lib.nameValuePair id {installation_mode = "allowed";}) extensions
      // {"*".installation_mode = "removed";};

    PasswordManagerEnabled = false;
    ShowHomeButton = false;

    # Sensitive: a Mac without MDM ignores these, so set them by hand there.
    RestoreOnStartup = 1;
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderKeyword = "duckduckgo.com";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
  };
in {
  mzwing.features."software/browser/chromium" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs: [pkgs.ungoogled-chromium];

    nixos.programs.chromium = {
      enable = true;
      extraOpts = policies;
    };

    darwin.homebrew.casks = ["ungoogled-chromium"];

    home = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      lock = lib.importJSON ../../../../data/chromium/extensions.lock.json;

      chromiumDir =
        if isDarwin
        then "${config.home.homeDirectory}/Library/Application Support/Chromium"
        else "${config.xdg.configHome}/chromium";

      # No policy covers these, and Chromium doesn't integrity-check them, so they're merged into the profile directly.
      profilePrefs.vertical_tabs.enabled = true;

      mergeProfilePrefs = pkgs.writeShellApplication {
        name = "chromium-merge-profile-prefs";
        runtimeInputs = [pkgs.jq];
        text = ''
          jq -c --argjson prefs ${lib.escapeShellArg (builtins.toJSON profilePrefs)} '. * $prefs' "$1" > "$1.tmp"
          mv "$1.tmp" "$1"
        '';
      };

      # Derived from the policies, so activation can tell whether this exact profile is installed.
      mobileconfigUUID = let
        hex = lib.toUpper (builtins.hashString "md5" (builtins.toJSON policies));
        part = start: length: builtins.substring start length hex;
      in "${part 0 8}-${part 8 4}-${part 12 4}-${part 16 4}-${part 20 12}";

      # Without MDM, macOS only enforces policies from a configuration profile the user installs by hand.
      mobileconfig = pkgs.writeText "chromium-policies.mobileconfig" (lib.generators.toPlist {escape = true;} {
        PayloadType = "Configuration";
        PayloadVersion = 1;
        PayloadIdentifier = "nix-config.chromium";
        PayloadUUID = mobileconfigUUID;
        PayloadDisplayName = "Chromium";
        PayloadScope = "User";
        PayloadContent = [
          (policies
            // {
              PayloadType = "org.chromium.Chromium";
              PayloadVersion = 1;
              PayloadIdentifier = "nix-config.chromium.policies";
              PayloadUUID = "D8773A86-1ABB-4027-9545-F65C9680A115";
            })
        ];
      });
    in {
      # ungoogled-chromium never downloads extensions itself, so each one is installed from a crx pinned in the lock.
      programs.chromium = {
        enable = true;
        # The cask and packages.nixos install the browser.
        package = null;
        extensions =
          lib.mapAttrsToList (name: id: let
            pin = lock.${id} or (throw "software/browser/chromium: ${name} is missing from data/chromium/extensions.lock.json; run `just chromium-extensions-update`");
          in {
            inherit id;
            inherit (pin) version;
            crxPath = pkgs.fetchurl {
              name = "${name}-${pin.version}.crx";
              inherit (pin) url hash;
            };
          })
          extensions;
      };

      home.activation = {
        # Not -q: an early exit would SIGPIPE `profiles` and fail the pipeline under pipefail.
        chromiumPolicies = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
          if ! /usr/bin/profiles show -type configuration | grep -F 'profileUUID: ${mobileconfigUUID}' >/dev/null; then
            run /usr/bin/open ${mobileconfig}
            warnEcho "Install the Chromium profile in System Settings > General > Device Management; until then Chromium keeps its previous extension policy."
          fi
        '');

        # SingletonLock exists while Chromium runs, and a running Chromium writes its in-memory prefs back over the merge.
        chromiumProfilePrefs = lib.hm.dag.entryAfter ["writeBoundary"] ''
          prefs=${lib.escapeShellArg "${chromiumDir}/Default/Preferences"}
          if [[ -L ${lib.escapeShellArg "${chromiumDir}/SingletonLock"} ]]; then
            warnEcho "Chromium is running, so its settings were left unchanged; quit it and switch again."
          elif [[ -f $prefs ]]; then
            run ${lib.getExe mergeProfilePrefs} "$prefs"
          fi
        '';
      };
    };
  };
}
