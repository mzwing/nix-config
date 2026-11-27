{
  description = "mzwing's nix config";

  # Nix wants a literal here, so this duplicates the list core/nix.nix builds from data/caches.nix and network/china-mirrors. Keep in step by hand.
  nixConfig = {
    substituters = [
      # "https://mirrors.cernet.edu.cn/nix-channels/store"
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      #"https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      # "https://mirror.nju.edu.cn/nix-channels/store"
      # "https://mirrors.cqupt.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org?priority=41"
      "https://cache.numtide.com?priority=41"
      "https://nix-cache.service.mzwing.eu.org"
      "https://cache.so1ve.dev"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-cache.service.mzwing.eu.org-1:ZI+74ziFu8O5j5jSAz45VTPo09uLYH7O8F2dBYBQYsk="
      "cache.so1ve.dev-1:SijyzF9iE/VZwMXgMpd/HrNX9iItDZ1tdiNdeGakQGY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    js-toolchain-overlay = {
      url = "github:so1ve/js-toolchain-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qiuchenly-cli = {
      url = "github:MZWNET/qiuchenly_cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    magpie = {
      url = "github:yetone/magpie-releases";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deliberately no `follows`: upstream only builds against its own nixpkgs pin, and overriding it means cache.numtide.com misses and everything rebuilds.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # No `follows` either, so the build matches nix-cache.service.mzwing.eu.org's
    baton.url = "github:MZWNET/baton";

    # No `follows`, so uptarn-agent matches cache.so1ve.dev's build
    uptarn.url = "github:so1ve/uptarn";

    # No `follows`, so the server matches nix-cache.service.mzwing.eu.org's build
    alpha-persei-cluster.url = "github:MZWNET/Alpha-Persei-Cluster";

    # Only for its home-manager module; the omp package still comes from llm-agents.
    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Moves the machinery, not the skills: those are pinned in data/skills/sources.lock.json.
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
