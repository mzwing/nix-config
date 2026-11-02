rec {
  host = "127.0.0.1";
  port = 3425;
  baseUrl = "http://${host}:${toString port}/v1";

  # Called over the tailnet by machines without a gateway of their own
  remote = "mzwing-azure";
}
