{
  mzwing.features."nixos/nspawn" = {
    meta.platforms = ["nixos"];

    # Booted by systemd-nspawn on another distro and sharing that machine's network, as `just nspawn-install` sets it up
    nixos = {hostname, ...}: {
      boot.isNspawnContainer = true;

      networking = {
        hostName = hostname;

        # The network stays the machine's to configure; a firewall here would also filter the machine's own sshd
        useDHCP = false;
        firewall.enable = false;
      };

      # The machine's own sshd holds port 22
      services.openssh.ports = [2222];

      # The build sandbox mounts a fresh /proc in a user namespace, which the files nspawn masks under /proc forbid
      nix.settings.sandbox = false;
    };
  };
}
