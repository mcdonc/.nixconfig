{ lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}

# p51 sleep stuff....
#
# Runtime PM for port ata1 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata1/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family USB 3.0 xHCI Controller /sys/bus/pci/devices/0000:00:14.0/power/control
# Runtime PM for port ata3 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata3/power/control
# Runtime PM for PCI Device Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/power/control
# Runtime PM for port ata4 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata4/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family Power Management Controller /sys/bus/pci/devices/0000:00:1f.2/power/control
# Runtime PM for PCI Device Intel Corporation CM238 Chipset LPC/eSPI Controller /sys/bus/pci/devices/0000:00:1f.0/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family PCI Express Root Port #1 /sys/bus/pci/devices/0000:00:1c.0/power/control
# Runtime PM for port ata2 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata2/power/control
# Runtime PM for PCI Device Realtek Semiconductor Co., Ltd. RTS525A PCI Express Card Reader /sys/bus/pci/devices/0000:3f:00.0/power/control
# Runtime PM for PCI Device Intel Corporation Xeon E3-1200 v6/7th Gen Core Processor Host Bridge/DRAM Registers /sys/bus/pci/devices/0000:00:00.0/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family PCI Express Root Port #5 /sys/bus/pci/devices/0000:00:1c.4/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family Thermal Subsystem /sys/bus/pci/devices/0000:00:14.2/power/control

# found via tlp-stat -e
# 17.0, 14.0, 1f.2, 1f.0, 1c.0, 3f:00.0, 00.0, 1c.4, 14.2
# 17.0 sata controller, ahci
# 14.0 USB controller, xhci_hcd
# 1f.2 Memory controller, (no driver)
# 1f.0 ISA bridge, (no driver)
# 1c.0 PCI bridge, pcieport
# 3f:00.0 nassigned class [ff00], rtsx_pci
# 00.0 Host bridge, skl_uncore
# 1c.4 PCI bridge, pcieport
# 14.2 Signal processing controller, intel_pch_thermal

# services.tlp = {
# settings = {

# allow sleep to work

# with AHCI_RUNTIME_PM_ON_AC/BAT set to defaults in battery mode, P51
# can't resume from sleep.  P50 can' sleep.
# DISK_DEVICES must be specified for AHCI_RUNTIME_PM
# DISK_DEVICES = "nvme0n1 nvme1n1 sda sdb";
# AHCI_RUNTIME_PM_ON_AC = "on";
# AHCI_RUNTIME_PM_ON_BAT = "on";

# with RUNTIME_PM_ON_BAT/AC set to defaults, P51 can't go to sleep (P50 can)
#RUNTIME_PM_ON_AC = "on";
#RUNTIME_PM_ON_BAT = "on";

# the below is pointless
#SATA_LINKPWR_ON_AC = "";
#SATA_LINKPWR_ON_BAT = "";
#RUNTIME_PM_DRIVER_DENYLIST = "mei_me nouveau radeon ahci xhci_hcd pcieport rtsx_pci skl_uncore intel_pch_thermal intel-lpss mei_hdcp mei";
# memory controller, ISA bridge, host bridge, PCIe root port #5/#13,#3,#9 thermal subsys
#RUNTIME_PM_DISABLE = "00:1f.2 00:1f.0 00:00.0 00:1c.4 00:1d.4 00:1c.2 00:1d.0 00:14.2";
#    };
#  };

