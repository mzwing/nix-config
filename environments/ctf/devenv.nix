{pkgs, ...}: {
  packages = with pkgs; [
    sleuthkit
    upx
  ];

  enterTest = ''
    mmls -V
    upx --version
  '';
}
