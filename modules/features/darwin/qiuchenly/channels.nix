{
  mzwing.features."darwin/qiuchenly/channels" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/qiuchenly"];

    darwin.mzwing.qiuchenly.channels = {
      default = null;
      community = "https://api1.xkji.com/api/v1";
    };
  };
}
