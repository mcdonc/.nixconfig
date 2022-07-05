{config, lib, ...}:

{
  services.tlp = {
    settings = {
      # DISK_DEVICES must be specified for AHCI_RUNTIME_PM settings to work right.
      DISK_DEVICES = "nvme0n1 nvme1n1 sda sdb";

      # with AHCI_RUNTIME_PM_ON_AC/BAT set to defaults in battery mode, P51
      # can't wake up and P50/P52 can't go to sleep.
      AHCI_RUNTIME_PM_ON_AC = "on";
      AHCI_RUNTIME_PM_ON_BAT = "on";

      # with RUNTIME_PM_ON_BAT/AC set to defaults, P50/P51 can't go to sleep.
      # P52 can't wake up.
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "on";

      USB_AUTOSUSPEND = "0";
      # Cambridge Silicon Radio, Ltd Bluetooth Dongle (HCI mode)
      # Synaptics, Inc. Metallica MIS Touch Fingerprint Reader
      USB_DENYLIST="0a12:0001 06cb:009a";
      # USB_EXCLUDE_BTUSB="1";

      # nvidia, nvme
      # 01:00.0 VGA compatible controller: NVIDIA Corporation GP107GLM [Quadro P1000 Mobile] (rev a1)
      # 02:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller SM981/PM981/PM983
      # Network controller: Intel Corporation Wireless-AC 9560 [Jefferson Peak] (rev 10)
      RUNTIME_PM_DISABLE = "01:00.0 02:00.0 00:14.0";
      # journalctl -o short-precise -k (this boot)
      # journalctl -o short-precise -k -b -1 (last boot)
    };
  };
}
