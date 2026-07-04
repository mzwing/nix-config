{
  mzwing.features."darwin/homebrew/brews" = {
    meta.platforms = ["darwin"];

    darwin = {
      homebrew.brews = [
        "cliproxyapiplus"
        "cloudflarewarpspeedtest"
        "container-compose"
        "crossover-trial-reset"
        "curl"
        "gryph"
        "hfd"
        "licensed"
        "llama.cpp"
        {
          name = "manboster@rc";
          link = true;
        }
        "mole"
        "nodejs"
        "pnpm"
        "samloader-rs"
        {
          name = "sing-box@alpha";
          link = true;
        }
        "stable-diffusion.cpp"
        "xcode-build-server"
        "yarn-completion"
      ];
    };
  };
}
