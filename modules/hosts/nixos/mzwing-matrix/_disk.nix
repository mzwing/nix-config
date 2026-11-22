{
  boot.loader.grub.enable = true;

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-path/pci-0000:01:01.0-scsi-0:0:0:0";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            mountpoint = "/";
            mountOptions = ["compress=zstd" "noatime"];
          };
        };
      };
    };
  };
}
