{
  hub = "mzwing-huaweicloud-gz";
  # Only relay the repos; nobody works in their copies
  transit = ["mzwing-azure" "mzwing-huaweicloud-gz" "mzwing-lycheen-us"];
  devices = {
    mzwing-MacBook-Pro = {
      id = "7HYKQ2F-QGRHYGV-OEXVX4U-2ZTCI3C-DTV57YM-OAQZTZU-AEQSAZK-V7IUDAS";
      address = "tcp://mzwing-macbook-pro:22000";
    };
    mzwing-azure = {
      id = "FXLKDTW-3CBTDGT-K77E4N7-QQTBJME-TA33GCJ-7JEWDVH-H6F7ILH-I6F4PQR";
      address = "tcp://mzwing-azure:22000";
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
    mzwing-lycheen-us = {
      id = "SL7WS7Y-RTGHYVU-MRX6HP2-UPWPRXQ-DTJSG4L-ZVERR64-SWRQFLG-K45AJQB";
      address = "tcp://mzwing-lycheen-us:22000";
    };
    mzwing-matrix = {
      id = "EP2K7TO-FSMM3VQ-QNQY73O-XM5D6GV-GOBXADC-FWXAXPZ-V6JH5H2-PXSXCQN";
      address = "tcp://mzwing-matrix:22000";
    };
  };
}
