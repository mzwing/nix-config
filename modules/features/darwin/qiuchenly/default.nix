{
  mzwing.features."darwin/qiuchenly" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.mzwing.qiuchenly;

      appLine = app: opts: "${app} ${lib.boolToString opts.precracked} ${opts.channel}\n";

      appsFile = pkgs.writeText "qiuchenly-apps" (
        lib.concatStrings (lib.mapAttrsToList appLine cfg.apps)
      );

      channelsFile = pkgs.writeText "qiuchenly-channels" (
        lib.concatStrings (lib.mapAttrsToList (name: url: "${name} ${url}\n") (lib.filterAttrs (_: url: url != null) cfg.channels))
      );

      injectFile = pkgs.writeText "qiuchenly-inject" (
        lib.concatMapStrings (app: app + "\n") (lib.unique cfg.inject)
      );
    in {
      options.mzwing.qiuchenly = {
        apps = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options.precracked = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Install the precracked package";
            };
            options.channel = lib.mkOption {
              type = lib.types.strMatching "[^[:space:]]+";
              default = "default";
              description = "Store channel used to install and update the application";
            };
          });
          default = {};
          description = "Applications installed and updated by qiuchenly";
        };

        channels = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr (lib.types.strMatching "[^[:space:]]+"));
          default = {};
          description = "Built-in and custom store channels";
        };

        inject = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Bundle IDs injected after Homebrew activation";
        };
      };

      config = {
        environment.systemPackages = [pkgs.qiuchenly-cli pkgs.aria2];

        system.activationScripts.postActivation.text = lib.mkAfter ''
          ( set -euo pipefail
            qiuchenly_run() {
              sudo --user=${lib.escapeShellArg config.homebrew.user} --set-home env PATH=${pkgs.aria2}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin ${pkgs.qiuchenly-cli}/bin/qiuchenly "$@"
            }

            qiuchenly_installed() {
              printf '%s\n' "$qiuchenly_list" | /usr/bin/awk -v target="$1" '$1 == target { found = 1 } END { exit !found }'
            }

            qiuchenly_install() {
              if [ "$2" = true ]; then
                qiuchenly_run install "$1" --precracked --channel "$3"
              else
                qiuchenly_run install "$1" --channel "$3"
              fi
            }

            mkdir -p /var/lib/qiuchenly
            if [ -s ${channelsFile} ]; then
              qiuchenly_channels="$(qiuchenly_run channel list)"
              while IFS=' ' read -r name url; do
                current_url="$(printf '%s\n' "$qiuchenly_channels" | /usr/bin/awk -v target="$name" '$1 == target { print $2; exit }')"
                if [ "$current_url" != "$url" ]; then
                  if [ -n "$current_url" ]; then
                    qiuchenly_run channel remove "$name"
                  fi
                  qiuchenly_run channel add "$name" "$url"
                fi
              done < ${channelsFile}
            fi

            qiuchenly_list="$(qiuchenly_run list --all)"

            while IFS=' ' read -r app precracked channel; do
              [ -n "$app" ] || continue
              if qiuchenly_installed "$app"; then
                qiuchenly_outdated="$(qiuchenly_run outdated "$app" --channel "$channel")"
                printf '%s\n' "$qiuchenly_outdated"
                if [ "$qiuchenly_outdated" != "没有可用更新" ]; then
                  qiuchenly_install "$app" "$precracked" "$channel"
                fi
              else
                qiuchenly_install "$app" "$precracked" "$channel"
              fi
            done < ${appsFile}

            if [ -f /var/lib/qiuchenly/apps ]; then
              while IFS=' ' read -r app precracked; do
                [ -n "$app" ] || continue
                if /usr/bin/awk -v target="$app" '$1 == target { found = 1 } END { exit !found }' ${appsFile}; then
                  continue
                fi
                if qiuchenly_installed "$app"; then
                  qiuchenly_run uninstall "$app" --yes
                else
                  qiuchenly_run cleanup "$app" --yes
                fi
              done < /var/lib/qiuchenly/apps
            fi

            cp ${appsFile} /var/lib/qiuchenly/apps.tmp
            mv /var/lib/qiuchenly/apps.tmp /var/lib/qiuchenly/apps

            if [ -s ${injectFile} ]; then
              qiuchenly_run inject --update
              while IFS= read -r app; do
                [ -n "$app" ] || continue
                qiuchenly_run inject "$app"
              done < ${injectFile}
            fi
          )
        '';
      };
    };
  };
}
