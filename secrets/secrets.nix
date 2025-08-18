let

  chrism = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia";
  tseaver = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9wBXRN8LimFia9KNhTEypd7q9GzHTYeC301e6y+QEoeNzf9//JuL23vUMUbSAPWW3aLfTQd29FFq1l3aEGNSpKkx1VKqRHWqHBC7HV0auU3RKy+bjKbCdhcIIiz7Exaa4MVyDWTCdSd+tHDpERKt7flhe2KZ8nb1JFBm8mjxtz/yO6RZmEXYCuUwRO1NlfS2mNzXDoY8crUxIUFuhUu5UHe2p3tGV7EGcqVVWGNvlpNk5qk+uUvmxs73xcYChfL7y/EwTp0FFuTRZpuxPv7fKR5ofjzannbnvl1Sz2db2ep6VH++6L7iu/Ehjwsl3rO9Or18N7XQYw9NOAxe/AvdhcFWMspI/rGvOi+Pq9Bq+2Gs4RoBCcFfVGqxFayvUWFioTD86jHeDXDXbAi4NKgtX3IeY+yBsvUyAg/8YRgEMkoMwMUWPP0lpMC04M4NpJ7uOEzFhl+kp42cpGl68TN1s177odhc9fNG9w25f4lgu234FsJNAX1Y/9QAijQkpfac=";
  alan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOvQSBJUaI8r2koqX1RJAq2+z/3ia2C5b+6q3iTMS9n";
  users = [ chrism tseaver alan ];

  lock802 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFnEHDKsVdV89438jO9rP3j5aPZORwF3olq1cvqcSQa";
  keithmoon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAKM2Y/WyecPzlYwodof33IhLgazClRN+T1SHoaNM9Yv";
  clonelock802 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3FP8bcCXHpaLfTetPPseJwqcCqek+sDrZAz/e33B61";
  arctor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0HfCNzDF+l0pM/u5D3aLGXu2ICxcJ/85rHElIHrI3v";
  enfold = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHgIJDWfZbCNOS5F7f7xp7QhN8v7deNfY5QZRkQsAkO";
  systems = [ lock802 keithmoon clonelock802 arctor enfold ];

in

{
  "pjsua.conf.age".publicKeys = [ chrism lock802 clonelock802 ];
  "pjsip.conf.age".publicKeys = [ chrism lock802 clonelock802 ];
  "wssecret.age".publicKeys = [ chrism lock802 clonelock802 arctor ];
  "passwords.age".publicKeys = [ chrism lock802 arctor ];
  "doors.age".publicKeys = [ chrism lock802 arctor ];
  "wifi.age".publicKeys = [ chrism lock802 clonelock802 ];
  "chris-mail-password-bcrypt.age".publicKeys = [ chrism arctor ];
  "chris-mail-password.age".publicKeys = [ keithmoon chrism ];
  "chris-mail-sasl.age".publicKeys = [ chrism keithmoon lock802 ];
  "enfold-gemini-key.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "enfold-pat.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "enfold-pydio-service-token.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold];
  "enfold-view-user-password.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold];
  "enfold-openai-api-key.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "enfold-pydio-realm-pem.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "enfold-droplet-passwords.age".publicKeys = [ chrism alan tseaver ];
  "enfold-slack-notify-url.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "enfold-cachix-authtoken.age".publicKeys = [ chrism alan tseaver keithmoon arctor enfold ];
  "mcdonc-cachix-authtoken.age".publicKeys = [ chrism tseaver keithmoon arctor enfold ];
  "mcdonc-unhappy-cachix-authtoken.age".publicKeys = [ chrism keithmoon ];
  "enfold-ngpt.age".publicKeys = [ chrism tseaver enfold ];
  "enfold-oai.age".publicKeys = [ chrism tseaver enfold ];
  "gandi-api.age".publicKeys = [ chrism tseaver arctor enfold keithmoon ];
  "enfold-alan-pat.age".publicKeys = [ chrism alan enfold ];
}
