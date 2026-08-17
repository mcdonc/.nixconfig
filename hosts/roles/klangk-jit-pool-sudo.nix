# Passwordless restart/status of the klangk JIT pool service only.
#
# The pool is restarted frequently while iterating on JIT runner bring-up;
# a scoped NOPASSWD rule avoids the password prompt each time without
# re-enabling blanket passwordless sudo. Matches bare `systemctl` too —
# /run/wrappers/bin/systemctl is what a normal shell resolves to.
{ ... }:

{
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "/run/current-system/systemd/bin/systemctl restart klangk-jit-pool.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/systemd/bin/systemctl status klangk-jit-pool.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/wrappers/bin/systemctl restart klangk-jit-pool.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/wrappers/bin/systemctl status klangk-jit-pool.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
