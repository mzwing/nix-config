let
  trustedTap = name: {
    inherit name;
    trusted = true;
  };
in {
  mzwing.features."darwin/homebrew/taps" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin = {
      homebrew.taps =
        map trustedTap [
          "AnInsomniacy/rayburst"
          "anomalyco/tap"
          "farion1231/ccswitch"
          "jetbrains/utils"
          "libkrun/krun"
          "mzwnet/tap"
          "octane0411/tap"
          "samzong/tap"
          "sinhong2011/tap"
          "tw93/tap"
        ]
        ++ [
          # Not named homebrew-*, so brew cannot find it by name alone.
          (trustedTap "yetone/magpie-releases" // {clone_target = "https://github.com/yetone/magpie-releases";})
        ];
    };
  };
}
