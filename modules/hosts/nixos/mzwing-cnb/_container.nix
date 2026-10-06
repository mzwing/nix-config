# CNB execs into this image instead of booting it, so `docker build` activates it once and nothing here runs under systemd.
{
  config,
  lib,
  pkgs,
  ...
}: let
  hm = config.home-manager.users.root;
in {
  boot.isContainer = true;

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

  system.activationScripts = {
    # The container runtime owns the mounts.
    specialfs = lib.mkForce "";

    sshHostKeys = lib.stringAfter ["etc"] ''
      ${config.services.openssh.package}/bin/ssh-keygen -A
    '';

    # CNB expects the Debian layout its docs install into, e.g. sshd at /usr/sbin/sshd.
    debianPaths = lib.stringAfter ["binsh"] ''
      ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/bash
      mkdir -p /usr/sbin
      ln -sfn ${config.services.openssh.package}/bin/sshd /usr/sbin/sshd
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

  # Run by the vscode pipeline in .cnb.yml once CNB has injected AGENIX_KEY.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "agenix-unlock" ''
      install -D -m 600 /dev/stdin /root/.ssh/agenix <<<"$AGENIX_KEY"
      exec ${lib.escapeShellArgs hm.systemd.user.services.agenix.Service.ExecStart}
    '')
  ];
}
