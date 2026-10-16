{
  mzwing.features."software/development" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          devenv
          devbox
          tokei
        ];

      darwin = pkgs: [pkgs.tuist];

      nixos = pkgs: [pkgs.licensed];
    };

    darwin.homebrew = {
      brews = [
        "licensed"
        "xcode-build-server"
      ];
      casks = [
        "openinterminal"
      ];
      masApps = {
        "Developer" = 640199958;
        "TestFlight" = 899247664;
        "Xcode" = 497799835;
      };
    };

    nixos = {
      config,
      lib,
      pkgs,
      type,
      ...
    }: let
      # security.wrappers now refuses non-ELF targets, and the ccache module's nix-ccache is still Perl. This is the C version from NixOS/nixpkgs#569444; drop once it reaches nixos-unstable.
      nixCcache =
        (pkgs.writeCBin "nix-ccache" ''
          #include <err.h>
          #include <regex.h>
          #include <unistd.h>

          #define CCACHE "${lib.getExe pkgs.ccache}"

          int main(int argc, char *argv[]) {
            regex_t allowed;
            if (regcomp(&allowed, "^(-[CVsz]|--(clear|version|show-stats|zero-stats))$", REG_EXTENDED | REG_NOSUB))
              err(1, "regcomp");

            // if any arg isn't on the allowlist, run `ccache` w/o args
            for (int i = 1; i < argc; i++)
              if (regexec(&allowed, argv[i], 0, nullptr, 0))
                argv[1] = nullptr;

            argv[0] = CCACHE;
            execve(CCACHE, argv, (char *[]){ "CCACHE_DIR=${config.programs.ccache.cacheDir}", nullptr });
            err(127, CCACHE);
          }
        '').overrideAttrs
        {env.NIX_CFLAGS_COMPILE = "-std=c23";};
    in {
      programs.ccache.enable = true;
      security.wrappers.nix-ccache.source = lib.mkForce (lib.getExe nixCcache);
      environment.systemPackages = lib.mkIf (type == "desktop") [pkgs.jetbrains.idea];
    };

    home = {
      lib,
      pkgs,
      type,
      ...
    }:
      lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && type == "desktop") {
        programs.jetbrains-remote = {
          enable = true;
          ides = with pkgs.jetbrains; [
            idea
          ];
        };
      };
  };
}
