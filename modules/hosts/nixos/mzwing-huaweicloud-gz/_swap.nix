{
  # 1.8G of RAM leaves a rebuild beside magpie no headroom. zram sits at priority 5, so the kernel only spills here once that is full.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2 * 1024;
    }
  ];
}
