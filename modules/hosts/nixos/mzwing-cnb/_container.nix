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

  services.openssh.enable = true;

  users.users.root.createHome = true;

  system.activationScripts = {
    # The container runtime owns the mounts.
    specialfs = lib.mkForce "";

    sshHostKeys = lib.stringAfter ["etc"] ''
      ${config.services.openssh.package}/bin/ssh-keygen -A
    '';

    # CNB's own scripts assume Debian paths.
    binBash = lib.stringAfter ["binsh"] ''
      ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/bash
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
