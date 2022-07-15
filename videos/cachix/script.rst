NixOS 31: Caching Source Builds With Cachix
===========================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Nixos builds anything it can't find at http://cache.nixos.org from source.

- Building the Linux kernel takes an hour or so.  I have to build my own
  because I apply a stupid patch to it.  Because the kernel needs to be
  rebuild, the Nvidia stuff needs to be rebuilt, etc.

- That means every system I stand up takes an hour longer to configure than if
  I used a stock kernel.

- NixOS is good at retrieving things from https://cache.nixos.org.  It'd be
  cool if you could have your own personal cache, wouldn't it?

- Tada: cachix.org.  14 day free trial, thereafter costs money per month.
  Pricing is geared towards small businesses.  https://www.cachix.org/pricing
  
- Create an account at https://cachix.org

- Create a personal authentication token.

- Create a binary cache (mine is named "mcdonc").

Caching New Store Paths Created During a ``nixos-rebuild``
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

- Before your rebuild::

    cachix authtoken <authtoken>
    cachix watch-store <cachename>

- Start the build (``nixos-rebuild``).

- Any store path created duing the build will be pushed up to your cache.

- In my case, here's what was pushed::

     $ cachix watch-store mcdonc                                                        
     Watching /nix/store for new store paths ...
     compressing and pushing /nix/store/j26mvs5ksi3648q4891r9jgh10xrv4nj-roland.patch (752.00 B)
     compressing and pushing /nix/store/21whdvnxxanvcvcchxsk45smxnfk7402-NVIDIA-Linux-x86_64-515.48.07.run (343.76 MiB)
     compressing and pushing /nix/store/5dpc9ih2sgahcqyrjhqhpyr2px7pfka8-linux-config-5.15.53 (236.89 KiB)
     compressing and pushing /nix/store/m2ascvyfrdph4jjzm1xaly5m23gzwsxp-linux-5.15.53-dev (619.36 MiB)
     compressing and pushing /nix/store/ygdq0lwyp2a7yg93dvihmjswp6mjrdby-linux-5.15.53 (105.50 MiB)
     compressing and pushing /nix/store/5w9hcqjdxwvrgjq0m010hv1h70sm2cww-nvidia-x11-515.48.07-5.15.53 (550.09 MiB)
     compressing and pushing /nix/store/z5rwpihhm54dvw561clmx1lw8l31jdmv-nvidia-x11-515.48.07-5.15.53-lib32 (281.11 MiB)
     compressing and pushing /nix/store/w0k97dzzaiyngr1zhp1r3sc351a1whqk-nvidia-x11-515.48.07-5.15.53-bin (132.24 MiB)
     compressing and pushing /nix/store/pirc6hlnh6274wrhkljcpm69r0c54vlv-system-generators (96.00 B)
     compressing and pushing /nix/store/wdhm8fiwsmg0kas39a58cz96bi07qs4m-unit-nvidia-hibernate.service (1.46 KiB)
     compressing and pushing /nix/store/5w9hcqjdxwvrgjq0m010hv1h70sm2cww-nvidia-x11-515.48.07-5.15.53 (550.09 MiB)
     compressing and pushing /nix/store/rixarhhx1knla5k36zf18b01ljz2wkhy-unit-nvidia-resume.service (1.48 KiB)
     compressing and pushing /nix/store/4iv685hbwxw1dvraq63w52bwk2jnvi38-unit-nvidia-suspend.service (1.45 KiB)
     compressing and pushing /nix/store/z5rwpihhm54dvw561clmx1lw8l31jdmv-nvidia-x11-515.48.07-5.15.53-lib32 (281.11 MiB)
     compressing and pushing /nix/store/3csypy7vydxbv14vjahkz2h3bp9zhamz-opengl-drivers-32bit (36.13 KiB)
     compressing and pushing /nix/store/1s6j4bn98dg0a1xam96fcjni9hhjkjln-nvidia-vaapi-driver-0.0.5 (78.31 KiB)
     compressing and pushing /nix/store/cj93b43v8amshkdijaad3h5frrrnpj79-system-shutdown (680.00 B)
     compressing and pushing /nix/store/31kbwr6qzxv5q5xm2ywlw260ffmzldb0-opengl-drivers (47.52 KiB)
     compressing and pushing /nix/store/h310326imywvbfk0ynqfw7gy8vi225p1-nixos-tmpfiles.d (2.02 KiB)
     compressing and pushing /nix/store/w0k97dzzaiyngr1zhp1r3sc351a1whqk-nvidia-x11-515.48.07-5.15.53-bin (132.24 MiB)
     compressing and pushing /nix/store/fcgbbdhws60x00bcdwibg3yrjqr0khjp-xserver.conf (3.80 KiB)
     compressing and pushing /nix/store/10fnvbwg7w2sqyjvhhy088rcwkvv5nci-tmpfiles.d (3.47 KiB)
     compressing and pushing /nix/store/c6cxn69kx38cgj47himr5ids2sf539l3-xserver-wrapper (1.28 KiB)
     compressing and pushing /nix/store/v46i29jr10jvkd130aljh3kj8zk3xy9g-sddm.conf (1.41 KiB)
     compressing and pushing /nix/store/mhn8zam483jgcxgnsny9gq9bmngf999v-Xsetup (3.62 KiB)
     compressing and pushing /nix/store/q05zslszc6n6c79ykna4l87lm4rxnhyr-libva-1.8.3 (309.94 KiB)
     compressing and pushing /nix/store/f2ps4ra7idl1xfbbil5swsgbzbv96vyq-steam-usr-multi (3.87 MiB)
     compressing and pushing /nix/store/mr4wp9x2yjfayfqlxv8ig9n6qs27983g-acpi-call-1.2.2-5.15.53 (17.77 KiB)
     compressing and pushing /nix/store/7lrabramsq6a88xhl92fb3rqm9i1w3jr-steam-run-usr-multi (3.87 MiB)
     compressing and pushing /nix/store/ww9w34nwy3v0ndh838krhavjim3cwn7h-steam-run-chrootenv-etc (704.00 B)
     compressing and pushing /nix/store/sq4sjfddrjr22p02yg5gsf2wbcvrfghl-steam-run-usr-target (4.24 MiB)
     compressing and pushing /nix/store/gsr1d17viqc5v3mjir5h2bbxb13j8isl-profile (1.27 KiB)
     compressing and pushing /nix/store/gda6rl2ym2zfs1420w8maznksrclyg7i-steam-chrootenv-etc (704.00 B)
     compressing and pushing /nix/store/9mgbzj6lgi90isvp4pflqml25h2rgz8i-profile (1.27 KiB)
     compressing and pushing /nix/store/6fn9ks5222zyb23wiwzjyr6j63v9rr3k-steam-usr-target (4.27 MiB)
     compressing and pushing /nix/store/3m1lkkn90drg03q0whdrndz7q3hdsn2y-steam-original-1.0.0.74 (3.49 MiB)
     compressing and pushing /nix/store/zb11a718mw2mzvr9vxjlprvsi6hydscc-steam-fhs (172.00 MiB)
     compressing and pushing /nix/store/iqbyss6r67wcp4kfkjc7qflkzszygqmv-steam-run-fhs (161.39 MiB)
     compressing and pushing /nix/store/sq873hbh2jjlkq8mzxgnqqjbl648m9qz-steam (6.77 KiB)
     compressing and pushing /nix/store/7dkc9ihv04srnca6p929l4z21ammxvgz-steam-init (848.00 B)
     compressing and pushing /nix/store/54nkvmbhqkslhnd8mar6d7j6vmf6gx5a-steam-wrapper.sh (1.25 KiB)
     compressing and pushing /nix/store/jcxca57bfz22fvmvghlm7s6cn9zqc4dm-steam-run-init (840.00 B)
     compressing and pushing /nix/store/8gnl1kagrmib8qgnjyxgdzs70wdkvh6n-steam-run (856.00 B)
     compressing and pushing /nix/store/1xbaz633sb1d1p6fi9303kpqq6lwivb5-steam-run (6.80 KiB)
     compressing and pushing /nix/store/vi41scsaa8bqa7qpk0h8j7zwy0nd7zqv-steam (1.65 KiB)
     compressing and pushing /nix/store/cbiwkbdnysy89ri1gi9wb4i4x61brm9i-steam-run (1.66 KiB)
     compressing and pushing /nix/store/wf8ln5i3ynk3p8dmqfyjagvap1qx8byw-nvidia-settings-515.48.07 (1.64 MiB)
     compressing and pushing /nix/store/yjk50sv816q416vjs01gg0149g83z8ip-nixos-rebuild (19.32 KiB)
     compressing and pushing /nix/store/xkinic61vv28rm807l96zlbiif52abhk-zoom-5.11.1.3595 (463.99 MiB)
     compressing and pushing /nix/store/l48s1gp8sklah9nc527ra4i8g91f1s3s-tlp-1.5.0 (540.82 KiB)
     compressing and pushing /nix/store/i7n77n3jpdcgi72j1bvrx3pzad1klx1l-system-path (13.29 MiB)
     compressing and pushing /nix/store/f9m9wwa0wadavzz1lvi6r8d9m1kw2m9j-google-chrome-103.0.5060.114 (267.79 MiB)

- Plenty of other options to send things to your cache *after* they've been
  built (e.g. when your use nix-build or nix-shell, or just know the store
  paths you actually want to put up there).  See
  https://docs.cachix.org/pushing.

Using The New Store Paths From the Cache On Other Systems
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

- On every system on which you want to use your cached store paths::

   cachix authtoken <authtoken>
   sudo cachix use <cachename>

- ``cachix use`` will cause files to be written to /etc/nixos (``cachix.nix`` and a
  directory named ``cachix``).

- Edit your configuration.nix to include the generated
  ``/etc/nixos/cachix.nix`` as an import.

- Run ``nixos-rebuild``.


