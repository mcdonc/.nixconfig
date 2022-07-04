{config, lib, ...}:

{
  services.tlp = {
    settings = {
      # DISK_DEVICES must be specified for AHCI_RUNTIME_PM settings to work right.
      DISK_DEVICES = "nvme0n1 nvme1n1 sda sdb";

      # with AHCI_RUNTIME_PM_ON_AC/BAT set to defaults in battery mode, P51
      # can't resume from sleep and P50 can't go to sleep.
      AHCI_RUNTIME_PM_ON_AC = "on";
      AHCI_RUNTIME_PM_ON_BAT = "on";

      # with RUNTIME_PM_ON_BAT/AC set to defaults, P51 can't go to sleep (P50 can)
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "on";
    };
  };
}
