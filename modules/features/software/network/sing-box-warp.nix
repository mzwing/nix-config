# For a server whose own IP can't carry Netflix, ChatGPT or IPv6
{
  mzwing.features."software/network/sing-box-warp" = {
    meta.platforms = ["nixos"];

    requires = ["software/network/sing-box"];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      warp = pkgs.writers.writePython3 "sing-box-warp" {flakeIgnore = ["E501"];} (builtins.readFile ../../../../scripts/sing_box_warp.py);
      warpConfig = (pkgs.formats.json {}).generate "sing-box-warp.json" {
        wgcf = lib.getExe pkgs.wgcf;
        singBox = lib.getExe config.services.sing-box.package;
        regionRestrictionCheck = lib.getExe pkgs.nur.repos.mzwing.regionrestrictioncheck;
        systemctl = "${config.systemd.package}/bin/systemctl";
        profile = "/var/lib/sing-box/warp.conf";
        fragment = "/run/sing-box/warp.json";
        # RegionRestrictionCheck's function for each rule set routes/rules/warp.json sends through warp.
        checks = [
          "MediaUnlockTest_Netflix"
          "MediaUnlockTest_ChatGPT"
        ];
        attempts = 10;
      };
    in {
      mzwing.sing-box.serverProfile = "server-warp";

      systemd.services.sing-box.serviceConfig.ExecStartPre = ["+${warp} render ${warpConfig}"];

      systemd.services.sing-box-warp = {
        description = "Replace the WARP account once its exit stops unlocking what sing-box routes through it";
        after = ["sing-box.service"];
        # A switch would otherwise restart a run in progress and wait for all of it.
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${warp} unlock ${warpConfig}";
        };
      };

      systemd.timers.sing-box-warp = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      environment.systemPackages = [pkgs.nur.repos.mzwing.regionrestrictioncheck];
    };
  };
}
