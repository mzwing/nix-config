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
      homebrew.taps = map trustedTap [
        "aninsomniacy/motrix-next"
        "anomalyco/tap"
        "farion1231/ccswitch"
        "jetbrains/utils"
        "leoafarias/fvm"
        "libkrun/krun"
        "mzwnet/tap"
        "octane0411/tap"
        "samzong/tap"
        "tw93/tap"
      ];
    };
  };
}
