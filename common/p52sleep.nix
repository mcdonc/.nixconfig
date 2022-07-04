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
    };
  };
}
