{
  mzwing.features."software/ai/harness/chatgpt" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["chatgpt"];
  };
}
