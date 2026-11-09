let
  syncthing = import ../../../../data/syncthing.nix;
  tailscale = import ../../../../data/tailscale.nix;

  # Inside <org>/<repo> but outside dot-dirs: .git keeps branch names like fix/build as paths
  outsideDotDirs = name: "(?d)/*/*/{,[!.]*/,[!.]*/**/}${name}";

  # No dist, and .codegraph keeps its .gitignore: some repos commit them
  ignorePatterns = ''
    (?d).DS_Store
    (?d).devenv
    (?d).direnv
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
    /cache
  '';

  mkSettings = lib: hostname: path: let
    peers = lib.filterAttrs (name: _: name != hostname) syncthing.devices;
  in {
    options = {
      globalAnnounceEnabled = false;
      localAnnounceEnabled = false;
      relaysEnabled = false;
      natEnabled = false;
      urAccepted = -1;
      crashReportingEnabled = false;
      listenAddresses = ["tcp://0.0.0.0:22000"];
    };
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
      type,
      ...
    }: let
      repos = "${config.services.syncthing.dataDir}/repos";
    in
      lib.mkIf (type == "server") {
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
          "L+ ${repos}/.stignore - - - - ${pkgs.writeText "syncthing-stignore" ignorePatterns}"
        ];
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22000];
      };

    home = {
      config,
      hostname,
      lib,
      secrets,
      type,
      ...
    }:
      lib.mkIf (type != "server") {
        age.secrets.syncthing-key.file = secrets."syncthing/${hostname}";

        services.syncthing = {
          enable = true;
          cert = "${../../../../data/syncthing/${hostname}.pem}";
          key = config.age.secrets.syncthing-key.path;
          settings = mkSettings lib hostname "${config.home.homeDirectory}/repos";
        };

        home.file."repos/.stignore".text = ignorePatterns;

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

        systemd.user.services.syncthing.Service.Environment = lib.mkIf (type == "container") [
          "all_proxy=socks5://${tailscale.userspaceProxy}"
          "ALL_PROXY_NO_FALLBACK=1"
        ];
      };
  };
}
