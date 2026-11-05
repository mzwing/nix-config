rec {
  host = "127.0.0.1";
  port = 3425;
  baseUrl = "http://${host}:${toString port}/v1";

  # Machines without a gateway of their own call this server's, through EdgeOne
  remote = "mzwing-azure";
  publicDomain = "ai.service.mzwing.eu.org";
}
