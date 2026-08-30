{
  mzwing.features."software/android" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.system = pkgs:
      with pkgs; [
        android-tools
        payload-dumper-go
        samloader-rs
        scrcpy
      ];
  };
}
