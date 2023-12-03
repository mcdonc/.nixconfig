========================================================
 NixOS 58: Exploring Encrypted DNS (DNS-over-TLS/HTTPS)
========================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
--------

- DNS isn't encrypted.  By default most people send these unencrypted DNS
  requests to whatever DNS server is configured via DHCP (usually offered by
  your ISP).

- Although most HTTP requests are over HTTPS these days, protecting the
  content, DNS requests will provide a trail of which hosts your PC contacted.
  E.g. visitng https://iamaclosetedfurry.com in your browser will spill the
  beans to whomever can see the traffic between the you and the DNS servers
  you're using.

- Side note: it's probably a good idea to disuse the DNS servers suggested by
  your ISP (even if they support encrypted DNS), as they almost certainly use
  the data about which websites you visit for marketing purposes.

Levels
------

There are a number of levels on which you can encrypt DNS requests.

Browser-Only
````````````

- If all you care about is encrypting DNS requests from your web browser and
  disusing your ISP's DNS while web browsing, enable encrypted DNS in your
  browser's settings.

  Firefox: visit "about:preferences#privacy" in a browser tab, scroll down to
  "DNS over HTTPS" and choose a security level.

  Can be done in Chrome too, but I don't use Chrome, so I'm not sure how to
  tell you how to do it.

  This is by far the simplest way to encrypt DNS requests.  It's what I've
  ended up going with.

System-Wide
```````````

- If you care about encrypting all DNS requests that your system makes, not
  just browser DNS requests.

- This setup assumes you're using ``networking.networkmanager.enable = true;``
  somewhere in your NixOS config, instructing NixOS to use NetworkManager to
  manage enabling and disabling particular network connections (rather than
  something like ``systemd-networkd``).  It may work with ``systemd-networkd``
  instead, but I haven't tried it.

- We make use of ``systemd-resolved`` in our system-wide configs, which is
  a DNS resolver tha ships as part of systemd.

``systemd-resolved`` Troubleshooting Tools
``````````````````````````````````````````

``resolvectl status``

``resolvectl query <hostname>``
   
System-Wide Config 1: Using ``systemd-resolved`` only
#####################################################

Here's the config::

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ]; # "use as default interface for all requests"
    # (see man resolved.conf)
    # let Avahi handle mDNS publication
    extraConfig = ''
      DNSOverTLS=opportunistic
      MulticastDNS=resolve
    '';
    llmnr = "true";
  };

  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "8.8.8.8#dns.google"
    "1.0.0.1#cloudflare-dns.com"
    "8.8.4.4#dns.google"
    "2606:4700:4700::1111#cloudflare-dns.com"
    "2001:4860:4860::8888#dns.google"
    "2606:4700:4700::1001#cloudflare-dns.com"
    "2001:4860:4860::8844#dns.google"
  ];

It means:

1. Enable ``systemd-resolved``

2. Instruct ``systemd-resolved`` to use DNS-over-TLS if the servers it attempts
   to contact support it (``DNSOverTLS=opportunistic``).

3. Instruct ``systemd-resolved`` to use DNSSEC (validation of request/response
   data).

3. Enable mDNS and LLMNR resolution (but not publication) for local name
   requests.

4. Use the nameservers in ``networking.nameservers`` as DNS servers.

System-Wide Config 2: Using ``Stubby`` and ``systemd-resolved`` together
########################################################################

Alternately, we can use ``Stubby``, a program that runs as a DNS server and
sends only DNS-over-TLS requests to the servers its configured to use (along
with ``systemd-resolved`` to point at it and potentially give us local name
resolution.  Here's the config::

    services.resolved = {
      enable = true;
      domains = [ "~." ]; # use as default interface for all requests
      # let Avahi handle mDNS publication
      extraConfig = ''
        MulticastDNS=resolve
      '';
      llmnr = "true";
    };
    
    networking = {
      nameservers = [ "::1" "127.0.0.1"];
    };

    ## DNS-over-TLS
    services.stubby = {
      enable = true;
      settings = {
        # ::1 cause error, use 0::1 instead
        listen_addresses = [ "127.0.0.1" "0::1" ];
        # https://github.com/getdnsapi/stubby/blob/develop/stubby.yml.example
        resolution_type = "GETDNS_RESOLUTION_STUB";
        dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
        tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
        tls_query_padding_blocksize = 128;
        idle_timeout = 10000;
        round_robin_upstreams = 1;
        tls_min_version = "GETDNS_TLS1_3";
        dnssec = "GETDNS_EXTENSION_TRUE";
        upstream_recursive_servers = [
          {
            address_data = "1.1.1.1";
            tls_auth_name = "cloudflare-dns.com";
          }
          {
            address_data = "1.0.0.1";
            tls_auth_name = "cloudflare-dns.com";
          }
          {
            address_data = "2606:4700:4700::1111";
            tls_auth_name = "cloudflare-dns.com";
          }
          {
            address_data = "2606:4700:4700::1001";
            tls_auth_name = "cloudflare-dns.com";
          }
          {
            address_data = "9.9.9.9";
            tls_auth_name = "dns.quad9.net";
          }
          {
            address_data = "149.112.112.112";
            tls_auth_name = "dns.quad9.net";
          }
          {
            address_data = "2620:fe::fe";
            tls_auth_name = "dns.quad9.net";
          }
          {
            address_data = "2620:fe::9";
            tls_auth_name = "dns.quad9.net";
          }
        ];
      };
    };

This config is different from the ``systemd-resolved``-only configuration in
these ways:

1. We do not have ``DNSOverTLS`` in the ``services.resolved`` ``extraConfig``
   section, because Stubby is handling this for us now.

2. We do not have ``dnssec="true"`` in the ``services.resolved`` config anymore
   because Stubby is handling this for us now.

3. Enable mDNS and LLMNR resolution (but not publication) for local name
   requests.
   
4. We point ``networking.nameservers`` only at Stubby on localhost.

5. We configure Stubby to run and do both DNS-over-TLS and DNSSEC, feeding it
   some servers we know can handle DNS-over-TLS.

Caveats for System-Wide Operation
`````````````````````````````````

- Note that things in ``extraConfig`` do not like comments via hashes following
  a directive.  This won't work::

      extraConfig = ''
        MulticastDNS=resolve # comment
      '';

  It must be::

      # comment
      extraConfig = ''
        MulticastDNS=resolve
      '';
  
  It also won't refuse to start.  It will just show a warning in the log and
  merrily proceeed.
      
- Regardless of which config you use above, resolution of "non-synthesized,
  single-label" names might not work as expected.  Eg. pay attention to ``ping
  anotherlocalmachine`` and ``ping anotherlocalmachine.local`` and make sure
  it's doing the right thing.

  ``ping anotherlocalmachine`` tries to uses LLMNR ("Link-Local Multicast Name
  Resolution") while ``ping another.localmachine.local`` will try to use mDNS
  ("Multicast DNS") resolution.  This is highly dependent on the machine you're
  attempting to contact participating in one or the other or both.  In general,
  if a machine is running ``mDNSResponder`` (Apple) or Avahi (Linux), trying to
  contact it with a ``.local`` extesion will work (not sure about Windows).  Or
  if you have a router that is willing to translate single-label names into IP
  addresses, and that router is consulted *only* for single-label or ``.local``
  names, it will work.  I know, it's complicated.

- If you get your DNS server from DHCP, all the work that you did to enable, in
  certain cases, system wide DNS-over-TLS *may* be ignored, and the DNS server
  obtained via DHCP will be used (unencrypted).  You may need to set your DHCP
  settings to ``Adresses only`` rather than ``Automatic`` to debug this.  It's
  fiddly.

- Even if you think you have it working, it's best to check things with
  Wireshark.  I often wound up in a place where DNS requests weren't being
  encrypted at all, despite thinking they should be.  At one point, I ended up
  in a place where DNS requests were going to both the DNS-over-TLS servers
  *and* a local unencrypted server somehow, defeating the purpose totally.

- These caveats are why I decided to abandon systemwide encrypted DNS, its just
  too complicated and fiddly to feel confident about working 100% all the time,
  and too easy to get into a place where you think it's working but it may not
  be.
