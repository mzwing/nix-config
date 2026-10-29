{lib, ...}: let
  fragmentDir = ../../../../data/sing-box;
  profileFragments = import fragmentDir;

  # Merged the way `sing-box merge` does: objects recursively, arrays appended in order, the first scalar kept.
  merge = values:
    if builtins.all builtins.isAttrs values
    then builtins.zipAttrsWith (_: merge) values
    else if builtins.all builtins.isList values
    then builtins.concatLists values
    else builtins.head values;

  profile = name: merge (map (fragment: lib.importJSON (fragmentDir + "/${fragment}")) profileFragments.${name});

  # A secret field is {"_secret": "<name in secrets/registry.nix>"}, with "quote": false when the secret holds JSON.
  withSecretPaths = secretPath: let
    # @ts: (value: any) => any
    walk = value:
      if builtins.isAttrs value
      then
        if value ? _secret
        then value // {_secret = secretPath value._secret;}
        else builtins.mapAttrs (_: walk) value
      else if builtins.isList value
      then map walk value
      else value;
  in
    walk;

  secretsIn = value:
    if builtins.isAttrs value
    then
      if value ? _secret
      then [value._secret]
      else lib.concatMap secretsIn (builtins.attrValues value)
    else if builtins.isList value
    then lib.concatMap secretsIn value
    else [];

  ageName = builtins.replaceStrings ["/"] ["-"];

  ageSecrets = secrets: attrs: names:
    lib.listToAttrs (map (name: lib.nameValuePair (ageName name) ({file = secrets.${name};} // attrs)) names);

  selfNodes = secrets: lib.filter (lib.hasPrefix "subs-check/self/") (builtins.attrNames secrets);

  subsCheckSecrets = secrets: ["subs-check/config"] ++ selfNodes secrets;

  clientFragments = secrets: lib.filter (lib.hasPrefix "sing-box/client/") (builtins.attrNames secrets);

  # Haru's Los Angeles nodes with clean IPs, taken from Haru's own list since subs-check renames every node after its exit.
  claudeNodeList = "subs-check/self/haru";
  selectClaudeNodes = ''{outbounds: [.outbounds[] | select(.tag | endswith(" - 洛杉矶纯净"))]}'';

  # One subs-check-pro run over every subscription, then the outbounds sing-box routes through, grouped by region and service. The speed tests pick this machine's Google cache node and WARP peer, and `render` fills them into what a profile merges.
  mkOutboundsCommand = {
    pkgs,
    secrets,
    secretPath,
    stateDir,
  }: let
    # subs-check-pro hands its callback its own environment.
    onComplete = pkgs.writeShellScript "subs-check-on-complete" ''
      printf '%s\n' "''${SUCCESS_COUNT:-unknown}" > "$SUBS_CHECK_SENTINEL"
    '';

    serveSelfNodes = lib.concatMapStrings (name: let
      file = "${baseNameOf name}.yaml";
    in ''
      cp "${secretPath name}" "$output/more/self/${file}"
      URL="$self/${file}" yq -i '.["sub-urls"] += [strenv(URL)]' "$config"
    '') (selfNodes secrets);

    seeds = fragmentDir + "/speed-test";
    speedTestResults = "${stateDir}/speed-test";

    # A value each machine measures for itself is {"_speedTest": "<name>"}, so a speed test never touches the repository.
    fillSpeedTests = ''walk(if type == "object" and has("_speedTest") then $results[._speedTest] // error("no \(._speedTest) result; run its speed test") else . end)'';

    # Everything a profile merges beyond its static fragments.
    renderFragments =
      lib.concatMapStrings ({
        name,
        source,
      }: ''
        jq --argjson results "$results" '${fillSpeedTests}' "${source}" > "$2/${name}.json"
      '') ([
          {
            name = "outbounds";
            source = "${stateDir}/outbounds.json";
          }
        ]
        ++ map (fragment: {
          name = lib.removeSuffix ".json" (baseNameOf fragment);
          source = fragmentDir + "/${fragment}";
        })
        profileFragments.measured
        ++ map (name: {
          name = baseNameOf name;
          source = secretPath name;
        }) (clientFragments secrets));
  in
    pkgs.writeShellApplication {
      name = "sing-box-outbounds";
      runtimeInputs = [
        pkgs.curl
        pkgs.gawk
        pkgs.jq
        pkgs.yq-go
        pkgs.nur.repos.mzwing.clash2sing-box
        pkgs.nur.repos.mzwing.cloudflarespeedtest
        pkgs.nur.repos.mzwing.cloudflarewarpspeedtest
        pkgs.nur.repos.mzwing.subs-check-pro
      ];
      text = ''
        # The merged config carries the subscriptions, and the outbounds every node's credentials.
        umask 077
        output="${stateDir}/subs-check"

        case "''${1:-}" in
          check)
            config="${stateDir}/subs-check.yaml"
            export SUBS_CHECK_SENTINEL="$output/.check-complete"
            rm -f "$SUBS_CHECK_SENTINEL"
            # cp gives the copies the secrets' read-only mode, so a rerun can't overwrite them.
            rm -rf "$output/more/self"
            mkdir -p "$output/more/self"

            OUTPUT="$output" CALLBACK=${onComplete} yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | .["output-dir"] = strenv(OUTPUT) | .["callback-script"] = strenv(CALLBACK)' ${../../../../data/subs-check/config.yaml} "${secretPath "subs-check/config"}" > "$config"

            self="http://127.0.0.1$(yq '.["listen-port"]' "$config")/more/self"
            ${serveSelfNodes}
            # There is no run-once mode: with `cron-expression` empty subs-check-pro checks once at startup and then blocks forever.
            subs-check-pro -f "$config" &
            pid=$!
            trap 'kill "$pid" 2>/dev/null || true' EXIT

            while [ ! -f "$SUBS_CHECK_SENTINEL" ]; do
              # A crash, a port clash or an unparseable config would otherwise hang here forever.
              if ! kill -0 "$pid" 2>/dev/null; then
                echo 'subs-check-pro exited before finishing a check' >&2
                exit 1
              fi
              sleep 5
            done

            printf 'check complete: %s nodes available\n' "$(cat "$SUBS_CHECK_SENTINEL")"
            ;;

          convert)
            work="$(mktemp -d)"
            trap 'rm -rf "$work"' EXIT

            # Unpacked only once a check needed it; entry labels are worth skipping over, not worth failing for.
            geo="$output/MaxMindData/GeoLite2-Country.mmdb"
            if [ -f "$geo" ]; then
              set -- --outbound-entry-geo-db "$geo"
            else
              echo "warning: no GeoIP database at $geo; entry locations will be missing" >&2
              set --
            fi

            clash2sing-box convert "${secretPath claudeNodeList}" | jq '${selectClaudeNodes}' > "$work/claude.json"

            # `(?<!-)` keeps a region group off the hyphenated qualifiers that sit elsewhere in a name: the CDN-side location in `HK¹-US⁰`, TikTok's `TK-US`, and the `|IN-XX` entry tag.
            clash2sing-box convert \
              "$output/sub/all.yaml" \
              "$work/claude.json" \
              "$@" \
              --outbound-group 'hk=(?<!-)\bHK\b' \
              --outbound-group 'tw=(?<!-)\bTW\b' \
              --outbound-group 'jp=(?<!-)\bJP\b' \
              --outbound-group 'sg=(?<!-)\bSG\b' \
              --outbound-group 'us=(?<!-)\bUS\b' \
              --outbound-group 'openai=GPT⁺' \
              --outbound-group 'claude= - 洛杉矶纯净$' \
              --outbound-group 'gemini=(?<!-)\bGM\b' \
              --outbound-group 'copilot=(?<!-)\bCP\b' \
              --outbound-group 'youtube=\bYT\b' \
              --outbound-group 'netflix=\bNF\b' \
              --outbound-group 'disney=D\+' \
              --outbound-group 'tiktok=\bTK\b' \
              -o "$work/outbounds.json"

            # The client fragments are merged beside these outbounds, and their own outbounds and endpoints join `proxy`.
            tags="$(jq -s 'map((.outbounds // []) + (.endpoints // []) | map(.tag)) | add' ${lib.concatMapStringsSep " " (name: ''"${secretPath name}"'') (clientFragments secrets)})"

            # The legacy VMess nodes drop all UDP except DNS, so QUIC through them hangs; TCP-only, each urltest group sends UDP through its fastest member that relays it.
            jq --argjson tags "$tags" '(.outbounds[] | select(.type == "vmess" and .alter_id > 0)).network = "tcp" | (.outbounds[] | select(.tag == "proxy")).outbounds += $tags' "$work/outbounds.json" > "${stateDir}/outbounds.json.new"
            mv "${stateDir}/outbounds.json.new" "${stateDir}/outbounds.json"
            ;;

          google-speed-test)
            work="$(mktemp -d)"
            trap 'rm -rf "$work"' EXIT

            # dl.google.com resolves per client subnet, so ECS queries from every province and ISP collect the cache nodes all over China.
            awk '{ print "https://dns.alidns.com/resolve?name=dl.google.com&type=A&edns_client_subnet=" $0 }' "${seeds}/google-subnets" | xargs curl -fsS --max-time 10 | jq -r '.Answer[]? | select(.type == 1) | .data' | sort -u > "$work/ip.txt"

            # TCPing means nothing under the TUN, which completes every handshake locally.
            CloudflareSpeedTest -httping -url https://dl.google.com/go/go1.25.1.linux-amd64.tar.gz -f "$work/ip.txt" -o "$work/result.csv"

            # The CSV is sorted by download speed (column 6), so a 0 on the first row means every download failed.
            best="$(awk -F, 'NR == 2 && $6 > 0 { print $1 }' "$work/result.csv")"
            if [ -z "$best" ]; then
              echo 'no node could download from dl.google.com' >&2
              exit 1
            fi

            mkdir -p "${speedTestResults}"
            jq -n --arg ip "$best" '{"google-pin": $ip}' > "${speedTestResults}/google.json"
            echo "google cache node -> $best"
            ;;

          warp-speed-test)
            family="''${2:-ipv4}"
            case "$family" in
              ipv4 | ipv6) ;;
              *)
                echo 'usage: sing-box-outbounds warp-speed-test [ipv4|ipv6]' >&2
                exit 1
                ;;
            esac

            work="$(mktemp -d)"
            trap 'rm -rf "$work"' EXIT

            endpoint="${secretPath "sing-box/client/warp"}"
            private_key="$(jq -r '.endpoints[0].private_key' "$endpoint")"
            public_key="$(jq -r '.endpoints[0].peers[0].public_key' "$endpoint")"
            reserved="$(jq -r '.endpoints[0].peers[0].reserved | "[\(join(", "))]"' "$endpoint")"
            CloudflareWarpSpeedTest -all -pri "$private_key" -pub "$public_key" -reserved "$reserved" -f "${seeds}/warp-$family" -o "$work/result.csv"

            # Row 1 of the body is the fastest: the tool sorts by latency ascending. IPv4 rows read `1.2.3.4:port`, IPv6 rows `[2606:...]:port`.
            best="$(awk -F, 'NR == 2 { print $1; exit }' "$work/result.csv")"
            if [ -z "$best" ]; then
              echo 'scan found no endpoint under the latency/loss limits' >&2
              exit 1
            fi
            address="$(printf '%s' "''${best%:*}" | tr -d '[]')"
            port="''${best##*:}"

            mkdir -p "${speedTestResults}"
            jq -n --arg address "$address" --argjson port "$port" '{"warp-address": $address, "warp-port": $port}' > "${speedTestResults}/warp.json"
            echo "warp peer -> $address:$port"
            ;;

          render)
            results="$(jq -s add "${speedTestResults}"/*.json)"
            ${renderFragments}
            ;;

          *)
            echo 'usage: sing-box-outbounds check|convert|google-speed-test|warp-speed-test [ipv4|ipv6]|render <directory>' >&2
            exit 1
            ;;
        esac
      '';
    };
in {
  mzwing.features."software/network/sing-box" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "home/agenix"
    ];

    packages.darwin = pkgs: [pkgs.nur.repos.mzwing.sing-box-alpha];

    darwin.homebrew.casks = ["sfm@alpha"];

    nixos = {
      config,
      hostname,
      lib,
      pkgs,
      secrets,
      type,
      ...
    }: let
      secretPath = name: config.age.secrets.${ageName name}.path;

      # Every profile here takes over the host through a TUN and joins the tailnet through its tailscale endpoint, so these hosts skip software/network/tailscale.
      service = settings: {
        services.sing-box = {
          enable = true;
          package = pkgs.nur.repos.mzwing.sing-box-alpha;
          # Merged with every JSON file placed in /run/sing-box before it starts.
          settings = withSecretPaths secretPath settings;
        };

        # 1.15 runs it as root and dropped the capabilities its sing-box user had, but nixpkgs still runs it as that user.
        systemd.services.sing-box.serviceConfig = {
          User = lib.mkForce "root";
          Group = lib.mkForce "root";
        };

        # Replies to the TUN arrive on an interface the main table doesn't route their source through.
        networking.firewall.checkReversePath = "loose";

        # sing-box answers every DNS query here, even lego's to the authoritative servers, and can serve the challenge record's cached absence for longer than lego keeps checking.
        security.acme.defaults.extraLegoFlags = ["--dns.propagation.wait" "1m"];

        age.secrets = ageSecrets secrets {} (secretsIn settings);
      };

      stateDir = "/var/lib/sing-box-outbounds";
      outboundsCommand = mkOutboundsCommand {inherit pkgs secrets secretPath stateDir;};
      checker = "subs-check";

      desktopSettings = let
        base = profile "linux";
      in
        base
        // {
          route =
            base.route
            // {
              # The checker measures each node from this network, not through the proxy its last results picked.
              rules =
                [
                  {
                    user = [checker];
                    action = "route";
                    outbound = "direct";
                  }
                ]
                ++ base.route.rules;
            };
        };
    in
      lib.mkMerge [
        (lib.mkIf (type == "server") (let
          settings = profile "server";
          inbounds = "sing-box/${hostname}/inbounds";
          caddySites = "caddy/${hostname}";

          # The group clash2sing-box's --outbound-group builds, without the proxy and urltest-proxy groups every conversion adds.
          claudeOutboundsCommand = pkgs.writeShellApplication {
            name = "sing-box-claude-outbounds";
            runtimeInputs = [
              pkgs.jq
              pkgs.nur.repos.mzwing.clash2sing-box
            ];
            text = ''
              clash2sing-box convert "${secretPath claudeNodeList}" | jq '${selectClaudeNodes} | .outbounds += [{type: "urltest", tag: "claude", outbounds: .outbounds | map(.tag)}]' > /run/sing-box/claude.json
            '';
          };

          warp = pkgs.writers.writePython3 "sing-box-warp" {flakeIgnore = ["E501"];} (builtins.readFile ../../../../scripts/sing_box_warp.py);
          warpConfig = (pkgs.formats.json {}).generate "sing-box-warp.json" {
            wgcf = lib.getExe pkgs.wgcf;
            singBox = lib.getExe config.services.sing-box.package;
            regionRestrictionCheck = lib.getExe pkgs.nur.repos.mzwing.regionrestrictioncheck;
            systemctl = "${config.systemd.package}/bin/systemctl";
            profile = "/var/lib/sing-box/warp.conf";
            fragment = "/run/sing-box/warp.json";
            # RegionRestrictionCheck's function for each rule set routes/rules/server.json sends through warp.
            checks = [
              "MediaUnlockTest_Netflix"
              "MediaUnlockTest_ChatGPT"
            ];
            attempts = 10;
          };
        in
          lib.mkMerge [
            (service settings)
            {
              age.secrets =
                ageSecrets secrets {} [inbounds claudeNodeList "tailscale/oauth-secret"]
                // ageSecrets secrets {owner = config.services.caddy.user;} [caddySites];

              services.caddy.extraConfig = "import ${secretPath caddySites}";
              systemd.services.caddy.reloadTriggers = [secrets.${caddySites}];

              networking.firewall = {
                allowedUDPPorts = lib.catAttrs "listen_port" settings.endpoints ++ lib.catAttrs "relay_server_port" settings.endpoints;
                # The proxy ports are in the inbounds secret; loopback inbounds sit behind Caddy.
                extraCommands = ''
                  for port in $(${lib.getExe pkgs.jq} -r '.inbounds[] | select(.listen != "127.0.0.1") | .listen_port' ${secretPath inbounds}); do
                    ip46tables -A nixos-fw -p tcp --dport "$port" -j nixos-fw-accept
                    ip46tables -A nixos-fw -p udp --dport "$port" -j nixos-fw-accept
                  done
                '';
              };
              systemd.services.firewall.restartTriggers = [secrets.${inbounds}];

              systemd.services.sing-box = {
                serviceConfig = {
                  ExecStartPre = [
                    "+${pkgs.coreutils}/bin/ln -sf ${secretPath inbounds} /run/sing-box/inbounds.json"
                    # tsnet reads TS_AUTHKEY only while it has no node state; the bare OAuth secret would enroll an ephemeral node, deleted soon after it goes offline.
                    "+${pkgs.writeShellScript "sing-box-tailscale-auth-key" ''
                      printf 'TS_AUTHKEY=%s?ephemeral=false&preauthorized=true\n' "$(<${secretPath "tailscale/oauth-secret"})" > /run/sing-box/tailscale.env
                    ''}"
                    "+${lib.getExe claudeOutboundsCommand}"
                    "+${warp} render ${warpConfig}"
                  ];
                  EnvironmentFile = "-/run/sing-box/tailscale.env";
                };
                restartTriggers = [secrets.${inbounds} secrets.${claudeNodeList}];
              };

              systemd.services.sing-box-warp = {
                description = "Replace the WARP account once its exit stops unlocking what sing-box routes through it";
                after = ["sing-box.service"];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${warp} unlock ${warpConfig}";
                };
              };

              systemd.timers.sing-box-warp = {
                wantedBy = ["timers.target"];
                timerConfig = {
                  OnCalendar = "hourly";
                  Persistent = true;
                };
              };

              environment.systemPackages = [pkgs.nur.repos.mzwing.regionrestrictioncheck];
            }
          ]))

        (lib.mkIf (type == "desktop") (lib.mkMerge [
          (service desktopSettings)
          {
            users.users.${checker} = {
              isSystemUser = true;
              group = checker;
            };
            users.groups.${checker} = {};

            # The checker also reads the client fragments: their tags join `proxy`, and the WARP one holds the identity its speed test probes with.
            age.secrets = ageSecrets secrets {owner = checker;} (subsCheckSecrets secrets ++ clientFragments secrets);

            systemd.services.sing-box-outbounds = {
              description = "Check the subscriptions and rebuild the sing-box outbounds from the nodes that pass";
              wants = ["network-online.target"];
              after = ["network-online.target"];
              serviceConfig = {
                Type = "oneshot";
                User = checker;
                StateDirectory = "sing-box-outbounds";
                ExecStart = [
                  "${lib.getExe outboundsCommand} check"
                  "${lib.getExe outboundsCommand} convert"
                ];
                # A reload would keep what sing-box rendered at its last start.
                ExecStartPost = "+${config.systemd.package}/bin/systemctl restart sing-box.service";
              };
            };

            # The speed tests are run by hand as the checker, whose traffic goes direct, followed by a restart of sing-box.
            environment.systemPackages = [outboundsCommand];

            systemd.timers.sing-box-outbounds = {
              wantedBy = ["timers.target"];
              timerConfig = {
                OnCalendar = "*-*-* 05:00:00";
                Persistent = true;
              };
            };

            systemd.services.sing-box = {
              serviceConfig.ExecStartPre = ["+${lib.getExe outboundsCommand} render /run/sing-box"];
              restartTriggers = map (name: secrets.${name}) (clientFragments secrets);
            };
          }
        ]))
      ];

    home = {
      config,
      lib,
      pkgs,
      secrets,
      ...
    }: let
      stateDir = "${config.xdg.stateHome}/sing-box";
      # agenix spells the darwin secrets directory as a command substitution, so these paths only resolve inside double quotes.
      secretPath = name: config.age.secrets.${ageName name}.path;

      outboundsCommand = mkOutboundsCommand {inherit pkgs secrets secretPath stateDir;};

      targets = ["macos" "android"];
      profileSecrets = lib.unique (lib.concatMap (target: secretsIn (profile target)) targets);
      staticProfile = target: pkgs.writeText "sing-box-${target}.json" (builtins.toJSON (profile target));

      rawfileArgs = lib.concatImapStringsSep " " (index: name: ''--rawfile s${toString index} "${secretPath name}"'') profileSecrets;
      secretTable = "{${lib.concatImapStringsSep ", " (index: name: "${builtins.toJSON name}: $s${toString index}") profileSecrets}}";

      # SFM and SFA fetch the result as a remote profile.
      profileCommand = pkgs.writeShellApplication {
        name = "sing-box-profile";
        runtimeInputs = [
          outboundsCommand
          pkgs.caddy
          pkgs.jq
          pkgs.nur.repos.mzwing.sing-box-alpha
        ];
        text = ''
          umask 077

          case "''${1:-}" in
            subs-check)
              exec sing-box-outbounds check
              ;;
            google-speed-test | warp-speed-test)
              exec sing-box-outbounds "$@"
              ;;
            macos)
              static=${staticProfile "macos"}
              listen=127.0.0.1:5858
              ;;
            android)
              static=${staticProfile "android"}
              # The phone fetches it over the LAN.
              listen=0.0.0.0:5858
              printf 'http://%s:5858/config.json\n' "$(ipconfig getifaddr en0)"
              ;;
            *)
              echo 'usage: sing-box-profile subs-check|google-speed-test|warp-speed-test [ipv4|ipv6]|macos|android' >&2
              exit 1
              ;;
          esac
          target=$1
          serve="${stateDir}/serve/$target"
          rendered="${stateDir}/rendered"

          sing-box-outbounds convert
          rm -rf "$rendered"
          mkdir -p "$serve" "$rendered"
          sing-box-outbounds render "$rendered"

          jq ${rawfileArgs} '${secretTable} as $secrets | walk(if type == "object" and has("_secret") then $secrets[._secret] | rtrimstr("\n") else . end)' "$static" > "${stateDir}/$target.json"
          sing-box merge "$serve/config.json" -c "${stateDir}/$target.json" -C "$rendered"

          # `override_android_vpn` is Android-only, and `sing-box check` refuses it everywhere else.
          jq 'del(.route.override_android_vpn)' "$serve/config.json" | sing-box check -c stdin

          exec caddy file-server --browse --listen "$listen" -r "$serve"
        '';
      };
    in
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        age.secrets = ageSecrets secrets {} (profileSecrets ++ subsCheckSecrets secrets ++ clientFragments secrets);

        home.packages = [profileCommand];
      };
  };
}
