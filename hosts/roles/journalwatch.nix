{ ... }:
{
  services.journalwatch.enable = true;
  services.journalwatch.mailTo = "chrism@repoze.org";
  services.journalwatch.priority = 5;
  services.journalwatch.interval = "*:00/10";
  services.journalwatch.accuracy = "1min";
}
