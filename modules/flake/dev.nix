# Working on this repo rather than on the machines it configures.
{inputs, ...}: {
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    apps.nixos-anywhere = {
      type = "app";
      program = "${inputs.nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere";
      meta.description = "Install NixOS hosts with nixos-anywhere.";
    };

    formatter = pkgs.writeShellApplication {
      name = "nix-config-format";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        if [ "$#" -eq 0 ]; then
          set -- .
        fi

        exec alejandra --exclude ./.devenv --exclude ./.devbox "$@"
      '';
    };
  };
}
