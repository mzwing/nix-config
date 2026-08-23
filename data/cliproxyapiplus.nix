# Where the local CLI proxy listens. The service and its clients are separate modules, so the address is written down once here.
rec {
  host = "localhost";
  port = 8317;
  baseUrl = "http://${host}:${toString port}/v1";
}
