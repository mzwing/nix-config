{
  mzwing.features."software/browser/yab" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["yab"];

    # What yab-mcp from npm runs; YAB_CLI makes the app binary act as its CLI.
    home.programs.mcp.servers.yab-browser = {
      command = "/Applications/yab.app/Contents/MacOS/yab";
      args = ["mcp"];
      env.YAB_CLI = "1";
    };
  };
}
