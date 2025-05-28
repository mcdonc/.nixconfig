let

  chrism = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia";
  tseaver = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9wBXRN8LimFia9KNhTEypd7q9GzHTYeC301e6y+QEoeNzf9//JuL23vUMUbSAPWW3aLfTQd29FFq1l3aEGNSpKkx1VKqRHWqHBC7HV0auU3RKy+bjKbCdhcIIiz7Exaa4MVyDWTCdSd+tHDpERKt7flhe2KZ8nb1JFBm8mjxtz/yO6RZmEXYCuUwRO1NlfS2mNzXDoY8crUxIUFuhUu5UHe2p3tGV7EGcqVVWGNvlpNk5qk+uUvmxs73xcYChfL7y/EwTp0FFuTRZpuxPv7fKR5ofjzannbnvl1Sz2db2ep6VH++6L7iu/Ehjwsl3rO9Or18N7XQYw9NOAxe/AvdhcFWMspI/rGvOi+Pq9Bq+2Gs4RoBCcFfVGqxFayvUWFioTD86jHeDXDXbAi4NKgtX3IeY+yBsvUyAg/8YRgEMkoMwMUWPP0lpMC04M4NpJ7uOEzFhl+kp42cpGl68TN1s177odhc9fNG9w25f4lgu234FsJNAX1Y/9QAijQkpfac=";
  users = [ chrism tseaver ];

  lock802 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFnEHDKsVdV89438jO9rP3j5aPZORwF3olq1cvqcSQa";
  keithmoon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAKM2Y/WyecPzlYwodof33IhLgazClRN+T1SHoaNM9Yv";
  systems = [ lock802 keithmoon ];

in

{
  "pjsua.conf.age".publicKeys = users ++ systems;
}
