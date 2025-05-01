NixOS XXX: Flox vs. Devenv
==========================

- Companion to video at 
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

Let's hit it.  I got opinions.

Similarities
++++++++++++

- Both improve software deployment repeatability for development and
  deployment.  Think npm lockfiles but for every package you'll ever need.

- Both are developer environment builders and a frontend to use Nix packages.

- Both are in competition with Dockerfiles and Docker Compose.

- Both of them install on any Linux platform, or any Mac platform.  Both can
  work around package unavailabilities on either.

- Neither makes you develop in a container.  You inherit your own local
  environment when developing (your editor, your shell configs, etc).

- Development environment isolation: No software installed to global OS
  locations.  Instead they use subshells: "flox activate" and "devenv shell".

- Both provide tools to allow you to containerize your development for
  production deployment.

- Both primarily written in Rust.  Devenv went from bash to Python to Rust.
  Seems like Flox started in Rust.

- Declarative config: flox [install] - > devenv "packages."

- Declarative: flox [vars] -> envenv "env."

- Declarative: flox [hook] -> devenv "enterShell"/tasks


Differences
+++++++++++

Neutral
_______

- Flox hides Nix entirely via imperative commands and in a second level editing
  a "manifest.toml".  Devenv can do something similar via "ad-hoc
  environments," but in order to use devenv fully you need to know some Nix and
  you need to commit to declaratively defining config.  Devenv also lets you
  sorta edit a bit of the environment in a YAML file and do that imperatively
  but it's not much help in reality.

- Flox tries hard to allow you to do imperative configuration.  Devenv not so
  much.  Immediacy of program availability.

- "flox init" creates an environment named after the parent directory.  Because
  devenv environments aren't composed on top of each other, "devenv init" is
  similar but not exactly the same.

  
Point: Flox
___________

- "flox search" helps you know which packages are useful on which OS, not so
  much on devenv; devenv mostly wraps the search that Nix has, which is pretty
  bad.
  
- "flox list" shows all the package versions installed into an environment.  No
  real equivalent in devenv.

- Devenv dumps you into a bash shell.  Flox does not, it dumps you into your
  existing shell as the subshell.

- devenv really wants you to be cd'ed into the directory (the DEVENV_ROOT) to
  execute various commands.  flox no so much, which is good.


Point: Devenv
_____________

- Flox environments are composed additively.  You run "flox activate" multiple
  times, e.g. once to install frontend packages and hooks for the frontend,
  once to install backend packages and hooks.  This isn't really how devenv
  works.  In devenv, an environment is composed from a single devenv.nix,
  although you can break it into bits using "profiles" which are thin wrappers
  around Nix conditions (e.g. frontend and backend).  Flox seems to believe
  that people imperatively find problems and solve them without switching
  context out of the flow of the commands they're excuting in the shell, and
  seem to believe that people ideally compose things this way.  I don't
  personally work like this, so it's not much help to me; I chose Nix for a
  reason, and that reason was a config file that I actually edited and owned.

- You inherit guru code in Flox via an environment, much as you do when you
  attempt to compose a Docker environment from multiple Dockerfiles (e.g. FROM
  python:3 AS base), although it's not really a perfect analogy.  In devenv,
  you inherit guru code in devenv via a "language" or a "service" and compose
  the environment yourself from them.  I prefer the latter because there is
  exactly one source of truth.

- Devenv "tasks" allow you to hook into the lifecycle of the environment more
  precisely.

- Flox doesn't have much of a service management component; devenv does via
  "processes." and various process mangager integrations
  (e.g. process-compose).

- Devenv allows you to define scripts that pull in ancillary packages from Nix
  that won't pretend to work outside of the active environment.  Very powerful,
  maybe the best bit of devenv on a day-to-day basis.

- Devenv, because it holds more fidelity with Nix than Flox does, documents how
  to override package versions via overlays.

- Devenv provides configuration for lots of git hooks, no real similar
  integration in Flox.

- "Hub"-ness.  "flox pull"

- "The flox catalog".  Something like DockerHub.  Flox the company provides the
  catalog.  Frontend for nixpkgs.  No non-cached packages?  This is the bit
  that makes me mort uncomfortable about Flox.  You upload your environments to
  it.  Maybe some lockin.  Devenv is produced by the same folks who produce
  Cachix, but "flox push" is just "git push" in devenv.

Unknown
_______

- Containerization?

Conclusion
__________

- Flox is more SF, Devenv is more Lubjiana.  But both are a step forward!  Only
  the market can decide.  Whichever one you prefer, it's hard to lose, but make
  no mistake that the market will pick the one you like the least, or neither.
