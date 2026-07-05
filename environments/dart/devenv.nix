{pkgs, ...}: {
  languages.dart.enable = true;

  packages = with pkgs; [
    flutter
  ];

  enterTest = ''
    dart --version
    flutter --version
  '';
}
