{
  mzwing.features."software/document" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          ghostscript
          glow
          imagemagick
          pandoc
          poppler
          poppler-utils
          qpdf
        ];

      nixos = pkgs:
        with pkgs; [
          kdePackages.okular
          typora
          wpsoffice-cn
        ];
    };

    darwin.homebrew = {
      casks = [
        "typora"
      ];
      masApps = {
        "Keynote讲演" = 409183694;
        "Microsoft Excel" = 462058435;
        "Microsoft PowerPoint" = 462062816;
        "Microsoft Word" = 462054704;
        "Numbers表格" = 409203825;
        "Pages文稿" = 409201541;
        "WPS Office" = 1443749478;
      };
    };
  };
}
