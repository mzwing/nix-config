rec {
  host = "127.0.0.1";
  port = 3425;
  baseUrl = "http://${host}:${toString port}/v1";

  # The servers sharing their gateway on the tailnet, by the provider name agents give each where no gateway runs.
  remotes = {
    magpie = "mzwing-azure";
    magpie-cn = "mzwing-huaweicloud-gz";
  };
}
