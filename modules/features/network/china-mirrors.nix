# flake.nix repeats this list for bootstrap; change both together.
let
  nixMirrorSubstituters = [
    # "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    # "https://mirrors.cqupt.edu.cn/nix-channels/store"
  ];

  homebrewMirrorEnv = {
    HOMEBREW_API_DOMAIN = "https://mirrors.cernet.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.cernet.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://mirrors.sustech.edu.cn/pypi/web/simple/";
  };
in {
  mzwing.features."network/china-mirrors" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin = {lib, ...}: {
      mzwing.nix.mirrorSubstituters = nixMirrorSubstituters;
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
      mzwing.nix.mirrorSubstituters = nixMirrorSubstituters;
    };

    home = {
      home.file = {
        # Gradle has no mirror setting, so an init script swaps Maven Central out wherever a build declares it
        ".gradle/init.d/china-mirrors.gradle".text = ''
          def mirror = 'https://mirrors.cloud.tencent.com/nexus/repository/maven-public/'

          def useMirror = { RepositoryHandler repositories ->
              repositories.withType(MavenArtifactRepository).configureEach { repository ->
                  if (repository.url.host in ['repo.maven.apache.org', 'repo1.maven.org']) {
                      repository.url = mirror
                  }
              }
          }

          beforeSettings { settings ->
              useMirror(settings.buildscript.repositories)
              useMirror(settings.pluginManagement.repositories)
              useMirror(settings.dependencyResolutionManagement.repositories)
          }

          allprojects {
              useMirror(buildscript.repositories)
              useMirror(repositories)
          }
        '';

        # The Plugin Portal hands whatever Maven Central also hosts over to Central, so it needs a mirror of its own, which only Aliyun offers
        ".gradle/gradle.properties".text = ''
          systemProp.org.gradle.internal.plugins.portal.url.override=https://maven.aliyun.com/repository/gradle-plugin
        '';

        ".cargo/config.toml".text = ''
          [source.crates-io]
          replace-with = "mirror"

          [source.mirror]
          registry = "sparse+https://mirrors.cernet.edu.cn/crates.io-index/"
        '';
      };

      home.sessionVariables = {
        GOPROXY = "https://mirrors.cloud.tencent.com/go/,direct";
        NPM_CONFIG_REGISTRY = "https://registry.npmmirror.com/";
      };
    };
  };
}
