# System-level Gitea on keithmoon (:3000).
#
# Private-by-default personal git host:
#   - open registration disabled; the only account is the admin created
#     at setup time (command in the comment at the bottom of this file)
#   - REQUIRE_SIGNIN_VIEW: every page (including repo browsing) requires
#     a signed-in session
#   - SSH transport disabled; push/pull over HTTP(S) with user + password
#     or a personal access token. Enable via the built-in SSH server on a
#     spare port if/when needed.
#   - sqlite backend; all state under /var/lib/gitea (module default)
{
  config,
  ...
}:

{
  services.gitea = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "keithmoon";
        ROOT_URL = "http://keithmoon:3000/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        DISABLE_SSH = true;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };
    };
  };
}

# Initial admin account (run once, after the service has started):
#
#   sudo -u gitea GITEA_WORK_DIR=/var/lib/gitea \
#     /run/current-system/sw/bin/gitea --config /var/lib/gitea/custom/conf/app.ini \
#     admin user create --admin \
#       --username <name> --email <email> \
#       --password '<password>' --must-change-password=false
#
# (gitea is not on the system PATH by default; if the path above fails,
#  take the binary from `systemctl cat gitea.service` ExecStart.)
