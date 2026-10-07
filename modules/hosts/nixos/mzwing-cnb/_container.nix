# CNB execs into this image instead of booting it, so `docker build` activates it once and nothing here runs under systemd.
{
  config,
  hostname,
  lib,
  pkgs,
  ...
}: let
  hm = config.home-manager.users.root;

  # Where Remote-SSH's server keeps each profile's extension list; without relativeLocation it loads them from the store instead of its own extensions dir.
  vscodeServer = pkgs.linkFarm "vscode-server" (lib.mapAttrsToList (name: profile: {
      name =
        if name == "default"
        then "extensions/extensions.json"
        else "data/User/profiles/${name}/extensions.json";
      path = pkgs.writeText "${name}-extensions.json" (builtins.toJSON (map (ext: removeAttrs (pkgs.vscode-utils.toExtensionJsonEntry ext) ["relativeLocation"]) profile.extensions));
    })
    hm.programs.vscodium.profiles);
in {
  boot.isContainer = true;

  networking.hostName = hostname;

  # boot.isContainer points Nix at a host daemon; here root owns the store and no daemon runs.
  environment.variables.NIX_REMOTE = lib.mkForce "local";

  # CNB's containers lack the namespaces the build sandbox needs, as in Nix's own container image.
  nix.settings.sandbox = false;

  services.openssh = {
    enable = true;
    # CNB runs sshd with UsePAM=no and logs in by password; without libxcrypt sshd falls back to OpenSSL's DES-only crypt and rejects every yescrypt hash.
    package = pkgs.openssh.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [pkgs.libxcrypt];
    });
  };

  users.users.root.createHome = true;

  # Remote-SSH downloads a VS Code server built for ordinary distros, matched to whatever version the client runs.
  programs.nix-ld.enable = true;

  system.activationScripts = {
    # The container runtime owns the mounts.
    specialfs = lib.mkForce "";

    sshHostKeys = lib.stringAfter ["etc"] ''
      ${config.services.openssh.package}/bin/ssh-keygen -A
    '';

    # CNB expects the Debian layout its docs install into, e.g. sshd at /usr/sbin/sshd; the loader link is normally systemd-tmpfiles' job.
    debianPaths = lib.stringAfter ["binsh"] ''
      ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/bash
      mkdir -p /usr/sbin /lib64
      ln -sfn ${config.services.openssh.package}/bin/sshd /usr/sbin/sshd
      ln -sfn ${config.environment.ldso} /lib64/ld-linux-x86-64.so.2
    '';

    # CNB skips roaming a ~/.gitconfig that already exists, and its tools write to it with `git config --global`.
    homeManager = lib.stringAfter ["users" "etc"] ''
      HOME=/root USER=root HOME_MANAGER_BACKUP_EXT=${config.home-manager.backupFileExtension} ${hm.home.activationPackage}/activate --driver-version 1
      touch /root/.gitconfig
    '';
  };

  home-manager.users.root.programs.git = {
    settings.user.name = lib.mkForce "mzwing";
    signing.signByDefault = lib.mkForce false;
  };

  # Run by the vscode pipeline in .cnb.yml, once CNB has injected AGENIX_KEY and mounted its own /root/.vscode-server over the image's.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vscode-server-extensions" ''
      cp -rLT --no-preserve=mode ${vscodeServer} /root/.vscode-server
    '')
    (pkgs.writeShellScriptBin "agenix-unlock" ''
      install -D -m 600 /dev/stdin /root/.ssh/agenix <<<"$AGENIX_KEY"
      exec ${lib.escapeShellArgs hm.systemd.user.services.agenix.Service.ExecStart}
    '')
  ];
}
