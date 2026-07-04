{
  mzwing.features."darwin/homebrew" = {
    meta.platforms = ["darwin"];

    darwin = {
      homebrew = {
        enable = true;

        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "zap";
        };
      };
    };
  };
}
