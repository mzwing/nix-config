{
  mzwing.features."nixos/container" = {
    meta.platforms = ["nixos"];

    # The runtime execs into the image instead of booting it, so systemctl3 runs NixOS's own units in systemd's place.
    nixos = {
      config,
      lib,
      pkgs,
      username,
      ...
    }: let
      systemctl3 = pkgs.nur.repos.mzwing.docker-systemctl-replacement;

      # What boot would have set up once.
      setupUnits =
        ["systemd-tmpfiles-setup.service"]
        ++ lib.optional config.services.openssh.enable "sshd-keygen.service"
        ++ ["home-manager-${username}.service"];
    in {
      boot.isContainer = true;

      # boot.isContainer points Nix at a host daemon; here root owns the store and no daemon runs.
      environment.variables.NIX_REMOTE = lib.mkForce "local";

      # Containers lack the namespaces the build sandbox needs, as in Nix's own container image.
      nix.settings.sandbox = false;

      environment.systemPackages = [systemctl3];

      system.activationScripts = {
        # The container runtime owns the mounts.
        specialfs = lib.mkForce "";

        setupUnits = lib.stringAfter ["users" "etc"] ''
          ${lib.getExe systemctl3} start ${lib.escapeShellArgs setupUnits}
        '';
      };
    };
  };
}
