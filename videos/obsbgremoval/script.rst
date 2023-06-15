NixOS 42: Using The OBS Background Removal Plugin on NixOS 23.05
================================================================

- Companion to video at

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- I configure obs-studio in a home-manager configuration::

    programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
    ];
  };  

- Alternate spelling if you want to do it globally::

    environment.systemPackages = with pkgs; [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          obs-backgroundremoval
        ];
      ...
      })

- You can tell if it's been installed if you run ``obs`` from the command line
  and you see something like this in the output::

    info: ---------------------------------
    info:   Loaded Modules:
    info:     obs-backgroundremoval.so
    ...
    
- Don't mix and match these two; in my experience, the home-manager config
  "wins" if you do.
  
- Add a V4L video source, right click on it afterwards, choose "Filters" and
  you should see it in the dropdown under "effects."
  
