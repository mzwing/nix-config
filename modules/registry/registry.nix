args: let
  registry = {
    nur.xddxdd = {
      author = "xddxdd";
      attic = {
        url = "https://attic.xuyh0120.win/lantian";
        publicKey = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
      };
    };
  };
in
  if args.asData or false
  then registry
  else {
    options.mzwing.registry.nur = args.lib.mkOption {
      type = args.lib.types.attrsOf args.lib.types.raw;
      default = {};
      description = "NUR author registry with cache metadata.";
    };

    config.mzwing.registry = registry;
  }
