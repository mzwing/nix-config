{lib, ...}: {
  i18n.defaultLocale = "en_SG.UTF-8";

  # home/base's zh_CN would otherwise override the system locale in mzwing's shells.
  home-manager.users.mzwing.home.sessionVariables = {
    LANG = lib.mkForce "en_SG.UTF-8";
    LANGUAGE = lib.mkForce "en_SG";
  };
}
