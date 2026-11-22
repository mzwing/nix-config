{
  mzwing.features."nixos/desktop" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      lib,
      pkgs,
      username,
      ...
    }: {
      networking.networkmanager.enable = true;

      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      programs.hyprland.enable = true;
      services.greetd = {
        enable = true;
        settings = {
          initial_session = {
            user = username;
            command = "start-hyprland";
          };
          default_session = {
            user = "greeter";
            command = "${lib.getExe pkgs.tuigreet} --cmd start-hyprland";
          };
        };
      };

      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/agenix"];

      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = [pkgs.qt6Packages.fcitx5-chinese-addons];
        };
      };

      fonts.packages = [pkgs.noto-fonts-cjk-sans pkgs.noto-fonts-cjk-serif pkgs.noto-fonts-color-emoji];
      xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      services.pulseaudio.enable = false;
    };

    home = {
      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = ''
          hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
          hl.config({
            animations = { enabled = false },
            decoration = { blur = { enabled = false }, shadow = { enabled = false } },
            misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
          })

          hl.on("hyprland.start", function()
            hl.exec_cmd("fcitx5")
          end)

          hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
          hl.bind("SUPER + D", hl.dsp.exec_cmd("fuzzel"))
          hl.bind("SUPER + Q", hl.dsp.window.close())
          hl.bind("SUPER + F", hl.dsp.window.fullscreen())
          hl.bind("SUPER + SHIFT + E", hl.dsp.exit())
          for _, direction in ipairs({ "left", "right", "up", "down" }) do
            hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
          end
          for i = 1, 9 do
            hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
            hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
          end
          hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
          hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
        '';
      };

      programs.fuzzel.enable = true;
      services.mako.enable = true;
      programs.waybar = {
        enable = true;
        systemd.enable = true;
      };
      services.wayvnc = {
        enable = true;
        autoStart = true;
        settings = {
          address = "127.0.0.1";
          port = 5900;
        };
      };
    };
  };
}
