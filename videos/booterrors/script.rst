NixOS 25: Suppressing Irritating Boot "Error" Messages
======================================================

- Companion to video at https://youtu.be/8G_ZPVrYmHY

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Thinkpad P52.  Secure boot disabled.  UEFI-only boot.

- During boot, this is displayed::
 
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR01._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR02._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR03._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR04._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR05._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR06._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR07._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR08._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR09._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR10._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)
    ACPI BIOS Error (bug): Could not resolve symbol [\_SB.PR00._CPC], AE_NOT_FOUND (20210730/psargs-330)
    ACPI Error: Aborting method \_SB.PR11._CPC due to previous error (AE_NOT_FOUND) (20210730/psparse-529)

- Has no operational negative effects that I can tell. Sleep works, battery
  life is ok.

- It'll come back around on the guitar to fix (via ``journalctl``) but right
  now I just want it out of my face.

- Set the following in your NixOS config::

   # silence ACPI "errors" at boot shown before NixOS stage 1 output (default is 4)
   boot.consoleLogLevel = 3;
    
- Rebuild.

- Bob, uncle.
  
