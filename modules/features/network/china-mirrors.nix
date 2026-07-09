let
  nixMirrorSubstituters = [
    # "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://mirrors.cqupt.edu.cn/nix-channels/store"
  ];
in {
  mzwing.features."network/china-mirrors" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {lib, ...}: let
      homebrewMirrorEnv = {
        HOMEBREW_API_DOMAIN = "https://mirrors.cernet.edu.cn/homebrew-bottles/api";
        HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.cernet.edu.cn/homebrew-bottles";
        HOMEBREW_BREW_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/brew.git";
        HOMEBREW_CORE_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git";
        HOMEBREW_PIP_INDEX_URL = "https://mirrors.aliyun.com/pypi/simple/";
      };
    in {
      mzwing.nix.extraSubstitutersBeforeDefault = nixMirrorSubstituters;
      environment.variables = homebrewMirrorEnv;

      system.activationScripts.homebrew.text = let
        envScript =
          lib.attrsets.foldlAttrs (
            acc: name: value:
              acc + "\nexport ${name}=${value}"
          ) ""
          homebrewMirrorEnv;
      in
        lib.mkBefore ''
          echo >&2 '${envScript}'
          ${envScript}
        '';
    };

    nixos = {
      mzwing.nix.extraSubstitutersBeforeDefault = nixMirrorSubstituters;
    };
  };
}
