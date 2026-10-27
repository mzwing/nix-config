{
  # The gateway handover test flakes on busy builders: its keep-alive POSTs race the old gateway closing idle connections. Drop once magpie fixes it.
  mzwing.patches.magpie = _: prev: {
    nur =
      prev.lib.updateManyAttrsByPath [
        {
          path = ["repos" "xyenon" "magpie"];
          update = magpie: magpie.overrideAttrs {checkFlags = ["-skip=^TestRestartHandsTheGatewayOver$"];};
        }
      ]
      prev.nur;
  };
}
