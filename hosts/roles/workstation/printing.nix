{ ... }:

{
  # match "Jun 19 13:00:01 thinknix512 cupsd[2350]: Expiring subscriptions..."
  systemd.services.cups = {
    overrideStrategy = "asDropin";
    serviceConfig.LogFilterPatterns = "~.*Expiring subscriptions.*";
  };

  # printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  #https://discourse.nixos.org/t/newly-announced-vulnerabilities-in-cups/52771/9
  systemd.services.cups-browsed.enable = false;

  
}
