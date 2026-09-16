{ pkgs, ... }:

let
  # The user who runs the appliance; the tap is owned by it, which is
  # what lets the unprivileged cloud-hypervisor open it.
  applianceUser = "chrism";
in
{
  # Host forwarding — the same machine-identity setting the appliance
  # ships internally.
  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";

  # Keep NetworkManager's hands off the appliance's devices (inert
  # where NetworkManager is not enabled).
  networking.networkmanager.unmanaged = [ "msksbr0" "mskstap0" ];

  systemd.services.msks-host-net = {
    description = "msks appliance host network (bridge, tap, NAT)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ iproute2 iptables ];
    script = ''
      set -e
      if ! ip link show dev msksbr0 >/dev/null 2>&1; then
        ip link add name msksbr0 type bridge
        ip addr add 192.168.77.1/24 dev msksbr0
        ip link set msksbr0 up
      fi
      if ! ip link show dev mskstap0 >/dev/null 2>&1; then
        ip tuntap add mode tap user ${applianceUser} mskstap0
        ip link set mskstap0 master msksbr0
        ip link set mskstap0 up
      fi
      ipt_rule() { # ipt_rule <table> <chain> <rule args...>: add if absent
        table="$1"
        shift
        iptables -t "$table" -C "$@" >/dev/null 2>&1 ||
          iptables -t "$table" -A "$@"
      }
      ipt_rule filter FORWARD -i msksbr0 -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
      ipt_rule filter FORWARD -o msksbr0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ipt_rule nat POSTROUTING -s 192.168.77.0/24 ! -o msksbr0 -j MASQUERADE
    '';
  };
}
