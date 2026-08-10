args: let
  registry = {
    nur.xddxdd = {
      author = "xddxdd";
      attic = {
        url = "https://attic.xuyh0120.win/lantian";
        publicKey = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
      };
    };
    nur.mzwing = {
      author = "mzwing";
      attic = {
        url = "https://mzwing.cachix.org";
        publicKey = "mzwing.cachix.org-1:tOO3NqAwrXyPCnecEl/0wXwparCRksM5TeuS/wZK+KA=";
      };
    };
    nur.so1ve = {
      author = "so1ve";
      attic = {
        url = "https://so1ve.cachix.org";
        publicKey = "so1ve.cachix.org-1:51jcW4FkJhiLcqPsiUx3nglRP469les8F9zjFxio1nw=";
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
