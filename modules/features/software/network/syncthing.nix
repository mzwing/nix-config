let
  syncthing = import ../../../../data/syncthing.nix;
  tailscale = import ../../../../data/tailscale.nix;

  # Inside <org>/<repo> but outside dot-dirs: .git keeps branch names like fix/build as paths
  outsideDotDirs = name: "(?d)/*/*/{,[!.]*/,[!.]*/**/}${name}";

  # No dist, and .codegraph keeps its .gitignore: some repos commit them
  # devenv writes hooks and pre-commit config pointing to each machine's own Nix store
  ignorePatterns = ''
    (?d).DS_Store
    (?d).devenv
    (?d).direnv
    (?d)/*/*/.git/hooks
    (?d).pre-commit-config.yaml
    (?d)node_modules
    ${outsideDotDirs "target"}
    ${outsideDotDirs "build"}
    (?d)/*/*/result
    (?d)/*/*/result-*
    (?d).gradle
    (?d).kotlin
    (?d).cxx
    (?d).next
    (?d).turbo
    (?d).android
    (?d).codegraph/[!.]*
    (?d)__pycache__
    (?d).venv
    (?d).git-cow
    /cache
  '';

  mkStignore = lib: hostname: let
    device = syncthing.devices.${hostname};
  in
    ignorePatterns
    + lib.optionalString (device ? repos) ''
      ${lib.concatMapStrings (repo: "!/${repo}\n") device.repos}*
    '';

  mkSettings = lib: hostname: path: let
    peers = lib.filterAttrs (name: _: name != hostname) syncthing.devices;
  in {
    inherit options;
    devices =
      lib.mapAttrs (_: peer: {
        inherit (peer) id;
        addresses = [peer.address];
      })
      peers;
    folders.repos = {
      inherit path;
      devices = builtins.attrNames peers;
    };
  };

  options = {
    globalAnnounceEnabled = false;
    localAnnounceEnabled = false;
    relaysEnabled = false;
    natEnabled = false;
    urAccepted = -1;
    crashReportingEnabled = false;
    listenAddresses = ["tcp://0.0.0.0:22000"];
  };

  # A first start would otherwise dial relays and STUN until syncthing-init patches the options, which InstaBox's abuse check took for a port scan
  initialConfig = lib:
    lib.concatStrings (
      ["<configuration>\n  <options>\n"]
      ++ lib.mapAttrsToList (name: value:
        if name == "listenAddresses"
        then lib.concatMapStrings (address: "    <listenAddress>${address}</listenAddress>\n") value
        else "    <${name}>${lib.generators.mkValueStringDefault {} value}</${name}>\n")
      options
      ++ ["  </options>\n</configuration>\n"]
    );
in {
  mzwing.features."software/network/syncthing" = {
    meta.platforms = ["darwin" "nixos"];
    requires = ["home/agenix" "software/network/tailscale"];

    nixos = {
      config,
      hostname,
      lib,
      pkgs,
      secrets,
      ...
    }: let
      repos = "${config.services.syncthing.dataDir}/repos";
    in
      lib.mkIf (lib.elem hostname syncthing.transit) {
        age.secrets.syncthing-key.file = secrets."syncthing/${hostname}";

        services.syncthing = {
          enable = true;
          cert = "${../../../../data/syncthing/${hostname}.pem}";
          key = config.age.secrets.syncthing-key.path;
          settings = lib.recursiveUpdate (mkSettings lib hostname repos) {
            folders.repos.versioning = {
              type = "trashcan";
              params.cleanoutDays = "14";
            };
          };
        };

        systemd.tmpfiles.rules = [
          "d ${repos} 0750 ${config.services.syncthing.user} ${config.services.syncthing.group} -"
          "L+ ${repos}/.stignore - - - - ${pkgs.writeText "syncthing-stignore" (mkStignore lib hostname)}"
        ];
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22000];
      };

    home = {
      config,
      hostname,
      lib,
      pkgs,
      secrets,
      type,
      ...
    }:
      lib.mkIf (!lib.elem hostname syncthing.transit) {
        age.secrets.syncthing-key.file = secrets."syncthing/${hostname}";

        services.syncthing = {
          enable = true;
          cert = "${../../../../data/syncthing/${hostname}.pem}";
          key = config.age.secrets.syncthing-key.path;
          settings = mkSettings lib hostname "${config.home.homeDirectory}/repos";
        };

        home.file."repos/.stignore".text = mkStignore lib hostname;

        home.activation.syncthingInitialConfig = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (lib.hm.dag.entryBetween ["reloadSystemd"] ["writeBoundary"] ''
          config=${lib.escapeShellArg "${config.xdg.stateHome}/syncthing/config.xml"}
          if [[ ! -e $config ]]; then
            run install -Dm600 ${pkgs.writeText "syncthing-config.xml" (initialConfig lib)} "$config"
          fi
        '');

        # Syncthing carries only mtime and size, so full stat checks rewrite every synced index
        programs.git.includes = [
          {
            condition = "gitdir:~/repos/";
            contents.core = {
              checkStat = "minimal";
              trustctime = false;
            };
          }
        ];

        systemd.user.services.syncthing = {
          Unit = {
            Requires = ["agenix.service"];
            After = ["agenix.service"];
          };
          Service.Environment = lib.mkIf (type == "container") [
            "all_proxy=socks5://${tailscale.userspaceProxy}"
            "ALL_PROXY_NO_FALLBACK=1"
          ];
        };
      };
  };
}
