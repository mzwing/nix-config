pkgs: let
  # The release channel, which is what the marketplace serves by default and what these extensions were on before Nix
  # managed them. Plain vscode-marketplace mixes in pre-releases, which silently moved 40 of them onto beta builds.
  m = pkgs.vscode-marketplace-release;
in {
  base = with m; [
    aaron-bond.better-comments
    alefragnani.bookmarks
    christian-kohler.path-intellisense
    davidanson.vscode-markdownlint
    editorconfig.editorconfig
    formulahendry.code-runner
    gruntfuggly.todo-tree
    gruntfuggly.triggertaskonsave
    irongeek.vscode-env
    mechatroner.rainbow-csv
    mrmlnc.vscode-json5
    ms-ceintl.vscode-language-pack-zh-hans
    oderwat.indent-rainbow
    redhat.vscode-yaml
    skellock.just
    tamasfe.even-better-toml
    tomoki1207.pdf
    tyriar.sort-lines
    ultram4rine.vscode-choosealicense
    upstash.context7-mcp
    w88975.code-translate
    wayou.vscode-todo-highlight
  ];

  git = with m; [
    codezombiech.gitignore
    donjayamanne.githistory
    eamodio.gitlens
    github.vscode-github-actions
    mhutchie.git-graph
  ];

  remote = with m; [
    github.codespaces
    github.remotehub
    ms-azuretools.vscode-containers
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.azure-repos
    ms-vscode.remote-explorer
    ms-vscode.remote-repositories
    ms-vscode.remote-server
  ];

  nixTools = with m; [
    arrterian.nix-env-selector
    bbenoist.nix
    datakurre.devenv
    jnoortheen.nix-ide
    mkhl.direnv
  ];

  shellTools = with m; [
    timonwong.shellcheck
  ];

  webUi = with m; [
    blanu.vscode-styled-jsx
    bradlc.vscode-tailwindcss
    formulahendry.auto-close-tag
    formulahendry.auto-rename-tag
    sibiraj-s.vscode-scss-formatter
    syler.sass-indented
    tobermory.es6-string-html
  ];

  webJs = [
    # Via nixpkgs so the version stays in step with the postPatch pointing oxc.path.oxlint/oxfmt at nixpkgs binaries;
    # that patch is written against 1.6x and fails on the older vsix either marketplace channel serves.
    pkgs.vscode-extensions.oxc.oxc-vscode
    m.antfu.browse-lite
    m.antfu.vite
    m.christian-kohler.npm-intellisense
    m.dbaeumer.vscode-eslint
    m.firefox-devtools.vscode-firefox-debug
    m.mariusalchimavicius.json-to-ts
    m.typescriptteam.native-preview
    m.vitest.explorer
    m.wix.vscode-import-cost
  ];

  react = with m; [
    dsznajder.es7-react-js-snippets
    pulkitgangwar.nextjs-snippets
  ];

  vue = with m; [
    antfu.goto-alias
    nuxt.mdc
    nuxtr.nuxtr-vscode
    vue.volar
  ];

  svelte = with m; [
    ardenivanov.svelte-intellisense
    fivethree.vscode-svelte-snippets
    svelte.svelte-vscode
  ];

  lit = with m; [
    bierner.lit-html
    lit.lit-snippets
    runem.lit-plugin
  ];

  solid = [m.ganko.ganko-vscode];

  deno = with m; [
    denoland.vscode-deno
    laurencebahiirwa.deno-std-lib-snippets
  ];

  bun = [m.oven.bun-vscode];

  lldb = [
    # vscode-marketplace carries 1.12.3, which the input's own version map rejects; open-vsx builds the identical drv but its fork of node_deps.nix still calls the deprecated stdenv.isDarwin.
    pkgs.vscode-extensions.vadimcn.vscode-lldb
    m.llvm-vs-code-extensions.lldb-dap
  ];

  rust = with m; [
    dustypomerleau.rust-syntax
    fill-labs.dependi
    rust-lang.rust-analyzer
  ];

  tauri = [m.tauri-apps.tauri-vscode];

  python = with m; [
    frhtylcn.pythonsnippets
    kevinrose.vsc-python-indent
    ms-python.black-formatter
    ms-python.debugpy
    ms-python.python
    ms-python.vscode-pylance
    njpwerner.autodocstring
    njqdev.vscode-python-typehint
  ];

  jupyter = with m; [
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
  ];

  go = with m; [
    golang.go
    msyrus.go-doc
  ];

  cpp = [
    # nix-vscode-extensions removed cpptools on aarch64-darwin; nixpkgs still packages it. Drop once it returns.
    pkgs.vscode-extensions.ms-vscode.cpptools
    m.cheshirekow.cmake-format
    m.ms-vscode.cmake-tools
    m.ms-vscode.cpp-devtools
    m.ms-vscode.cpptools-themes
    m.ms-vscode.makefile-tools
  ];

  java = with m; [
    dotjoshjohnson.xml
    naco-siren.gradle-language
    redhat.java
    redhat.vscode-xml
    vscjava.vscode-gradle
    vscjava.vscode-java-debug
    vscjava.vscode-java-dependency
    vscjava.vscode-java-test
    vscjava.vscode-maven
  ];

  kotlin = with m; [
    fwcd.kotlin
    mathiasfrohlich.kotlin
  ];

  dart = with m; [
    dart-code.dart-code
    dart-code.flutter
  ];

  swift = with m; [
    sweetpad.sweetpad
    swiftlang.swift-vscode
  ];

  ruby = with m; [
    shopify.ruby-lsp
    sorbet.sorbet-vscode-extension
  ];

  docs = with m; [
    gera2ld.markmap-vscode
    mirone.milkdown
    myriad-dreamin.tinymist
  ];

  # zamerick.vscode-caddyfile-syntax is gone on purpose: its 1.0.4 vsix ships one file twice and will not unpack.
  ops = with m; [
    ahmadalli.vscode-nginx-conf
    claui.packaging
    matthewpi.caddyfile-support
    nico-castell.linux-desktop-file
  ];

  zig = [m.ziglang.vscode-zig];

  ctf = [
    m."13xforever".language-x86-64-assembly
    m.ms-vscode.hexeditor
  ];

  typenix = [pkgs.nur.repos.mzwing.vscode-extensions.ryanrasti.typenix];
}
