rec {
  host = "127.0.0.1";
  port = 3425;
  baseUrl = "http://${host}:${toString port}/v1";
}
