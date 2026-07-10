{
  mzwing.features."nixos/server/disko-vda-ext4" = {
    meta.platforms = ["nixos"];

    nixos = {lib, ...}: {
      disko.devices.disk.main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            bios-boot = {
              size = "1M";
              type = "EF02";
            };

            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                extraArgs = [
                  "-L"
                  "nixos"
                ];
                mountpoint = "/";
              };
            };
          };
        };
      };

      boot.loader.grub.devices = lib.mkForce ["/dev/vda"];
    };
  };
}
