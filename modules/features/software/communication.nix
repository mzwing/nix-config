{
  mzwing.features."software/communication" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin.homebrew = {
      casks = [
        "discord"
        "element"
      ];
      masApps = {
        "钉钉" = 1435447041;
        "飞书" = 1551632588;
        "企业微信" = 1189898970;
        "腾讯会议" = 1484048379;
        "微信" = 836500024;
        "QQ" = 451108668;
        "Telegram" = 747648890;
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ayugram-desktop
        discord
        element-desktop
        feishu
        qq
        wechat
        wemeet
        nur.repos.xddxdd.dingtalk
      ];
    };
  };
}
