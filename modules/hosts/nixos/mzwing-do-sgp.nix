{
  mzwing.hosts.nixos.mzwing-do-sgp = {
    hostname = "debian-s-4vcpu-8gb-240gb-intel-sgp1";
    system = "x86_64-linux";
    username = "mzwing";
    profiles = ["nixos-server"];
    features = [
      "nixos/lustrate"
      "nixos/digitalocean-sgp"
    ];
  };
}
