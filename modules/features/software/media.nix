let
  systemMediaPackages = pkgs:
    with pkgs; [
      ffmpeg-full
      ffmpegthumbnailer
    ];
in {
  mzwing.features."software/media" = {
    meta.platforms = ["darwin"];

    darwin = {pkgs, ...}: {
      environment.systemPackages = systemMediaPackages pkgs;
      homebrew.casks = [
        "bakamusic"
        "kid3"
        "mac-music-player"
        "piliplus"
        "vlc"
        "xld"
      ];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemMediaPackages pkgs
        ++ (with pkgs; [
          kid3
          piliplus
          vlc
        ]);
    };
  };
}
