{
  mzwing.features."home/agenix" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      config,
      inputs,
      ...
    }: {
      imports = [
        inputs.agenix.homeManagerModules.default
      ];

      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/agenix"
      ];
    };
  };
}
