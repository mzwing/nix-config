{
  hub = "mzwing-huaweicloud-gz";
  devices = {
    mzwing-MacBook-Pro = {
      id = "7HYKQ2F-QGRHYGV-OEXVX4U-2ZTCI3C-DTV57YM-OAQZTZU-AEQSAZK-V7IUDAS";
      address = "tcp://mzwing-macbook-pro:22000";
    };
    mzwing-cnb = {
      id = "HOEKYXM-MHNKCN6-4AZGWND-35ZDLFH-JNM2HMT-S2B26V5-URISTLD-75UXXAF";
      address = "tcp://mzwing-cnb:22000";
      repos = ["MZWNET/baton" "MZWNET/qiuchenly_cli" "mzwing/nix-config"];
    };
    mzwing-huaweicloud-gz = {
      id = "JLVGPYZ-SAMSW6N-4HUYYZO-QH5LDQU-MERMP3J-FAFLOVE-XCPXNTM-QLCKXA6";
      address = "tcp://mzwing-huaweicloud-gz:22000";
    };
    mzwing-instabox = {
      id = "7IRXMAA-2A25TWB-QXZUBYY-Q2FSHR7-5QOPPS4-VKAJ2PE-DSKZOAE-JS43MQJ";
      address = "tcp://mzwing-instabox:22000";
      repos = ["MZWNET/baton" "mzwing/nix-config"];
    };
  };
}
