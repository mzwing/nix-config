{
  mzwing.features."software/media" = {
    meta.platforms = ["darwin"];

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ffmpeg-full
        ffmpegthumbnailer
      ];

      homebrew.casks = [
        "bakamusic"
        "bewlycat"
        "kid3"
        "mac-music-player"
        "piliplus"
        "vlc"
        "xld"
      ];
    };
  };
}
