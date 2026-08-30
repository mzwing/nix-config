{
  mzwing.features."software/media" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          ffmpeg
          ffmpegthumbnailer
        ];

      nixos = pkgs:
        with pkgs; [
          kid3
          piliplus
          vlc
        ];
    };

    darwin.homebrew.casks = [
      "bakamusic"
      "kid3"
      "mac-music-player"
      "piliplus"
      "vlc"
      "xld"
    ];
  };
}
