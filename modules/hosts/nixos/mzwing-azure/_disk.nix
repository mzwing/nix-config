# The blank 64G disk on LUN 1 is pooled with the OS disk into one 128G root, so root now needs both disks: detach the data disk and the machine stops booting.
# LVM does the pooling because disko cannot express a multi-device btrfs; btrfs itself only ever sees the one LV.
{
  disko.devices = {
    disk = {
      # /dev/sd* order is not stable — the data disk claimed /dev/sda here — but Azure always puts the OS disk on LUN 0.
      os = {
        type = "disk";
        device = "/dev/disk/by-path/acpi-MSFT1000:00-scsi-0:0:0:0";
        content = {
          type = "gpt";
          partitions = {
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

            pv = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };

      data = {
        type = "disk";
        device = "/dev/disk/by-path/acpi-MSFT1000:00-scsi-0:0:0:1";
        content = {
          type = "gpt";
          partitions.pv = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";

      lvs = {
        # 1G of RAM does not survive a rebuild on its own. zram sits at priority 5, so the kernel only spills here once that is full.
        swap = {
          size = "4G";
          content.type = "swap";
        };

        root = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            mountpoint = "/";
            # The nix store compresses roughly two to one, and this disk tops out around 50 MB/s, so zstd earns its CPU back.
            mountOptions = ["compress=zstd" "noatime"];
          };
        };
      };
    };
  };
}
