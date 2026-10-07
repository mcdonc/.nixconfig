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
#   - fronted by nginx at https://keithmoon.tail33f8f4.ts.net/gitea/ (see
#     roles/pocket-id.nix); plain HTTP on :3000 still serves git operations
#     directly (use http://<host-ip>:3000/gitea/<owner>/<repo>.git)
#   - Gitea Actions enabled; existing repos still need the Actions unit
#     turned on per repo (repo Settings -> Repository -> Actions). A
#     runner must be registered separately (Site Administration ->
#     Actions -> Runners) before workflows can execute.
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
        DOMAIN = "keithmoon.tail33f8f4.ts.net";
        ROOT_URL = "https://keithmoon.tail33f8f4.ts.net/gitea/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        DISABLE_SSH = true;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };
      # Global defaults for the OIDC auth source (the source itself —
      # discovery URL + client id/secret — lives in Gitea's database and is
      # added once via `gitea admin auth add-oauth`; see the comment at the
      # bottom of this file).
      oauth2_client = {
        OPENID_CONNECT_SCOPES = "email profile";
        # map the IdP's preferred_username claim to Gitea usernames
        USERNAME = "preferred_username";
        # never auto-create accounts from the IdP (single-user instance);
        # first SSO login shows the account-linking page instead
        ENABLE_AUTO_REGISTRATION = false;
        ACCOUNT_LINKING = "login";
      };
      actions = {
        ENABLED = true;
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
