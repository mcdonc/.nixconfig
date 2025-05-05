NixOS 98: Flox vs. Devenv
=========================

- Companion to video at 
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

Been a while but I got opinions.

Similarities
++++++++++++

- Both improve software deployment repeatability for development and
  deployment.  Think npm lockfiles but for every package you'll ever need.

- Both are development environment builders and a frontend to use Nix packages,
  useful for creating repeatable builds that your team can share.

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

- Both support declarative configuration.

  - Declarative config: flox [install] - > devenv "packages."

  - Declarative: flox [vars] -> envenv "env."

  - Declarative: flox [hook] -> devenv "enterShell"/tasks


Differences
+++++++++++

Neutral
_______

- "flox init" creates an environment named after the parent directory.  The
  environment has a name.  Because devenv environments aren't composed from
  other devenv environments, "devenv init" is similar but not exactly the same;
  a devenv checkout doesn't really have a "name."

- Flox hides Nix entirely via imperative commands and in a second level editing
  a "manifest.toml".  Devenv can do something similar via "ad-hoc
  environments," but in order to use devenv fully you need to know some Nix and
  you need to commit to declaratively defining config.  Devenv does let you
  sorta edit a bit of the environment in a YAML file imperatively but it's not
  much help in reality.

- Flox tries hard to allow you to do imperative configuration.  Devenv not so
  much.  Immediacy of program availability.

Point: Flox
___________

- Small but important bits from a team-buyin standpoint.

  - In flox, files are hidden in .flox directory, devenv's files must be
    visible to everyone at the root of the checkout directory.

  - flox attempts to invoke your own shell, while devenv dumps you into a bash
    shell.  It is possible to invoke your own shell when devenv shell is
    called, but I didn't find it particularly easy.

  - flox search is fast.  devenv search is slow and requires that you be cd'ed
    into the root of the devenv.

- "flox search"/"flox show"/"flox install" allows you to choose a package
  version.  While it's possible to do some reacharounds to select a specific
  package version using devenv, it's much less straightforward and requires
  advanced knowledge (overlays, specific hashes of nixpkgs).  Never needing to
  know how to do this this is probably the most helpful feature of Flox
  vs. devenv.

- "flox search" helps you know which packages are useful on which OS, not so
  much on devenv; devenv mostly wraps the search that Nix has, which is pretty
  bad.
  
- "flox list" shows all the package versions installed into an environment.  No
  real equivalent in devenv.

Point: Devenv
_____________


- Devenv allows you to generate scripts that pull in ancillary packages from
  Nix that won't pretend to work outside of the active environment.  Very
  powerful, maybe the best bit of devenv on a day-to-day basis.  In devenv
  you're not just choosing the versions of things that other people might
  deliver, you're composing your own extensions too via Nix and it's turtles
  all the way down.

- Devenv provides options that set up common things for a particular language
  (e.g. Python, Haskell, Rust, many others) via its "language." features.

- Devenv has prechewed defintions of "services" e.g. postgres, kafka, redis
  that will start preconfigured processes for you, allowing you to specify
  specific overrides as necessary.

- You can also define your own process commands.

- Flox doesn't have much of a service management component; devenv does via
  "processes." and various process mangager integrations
  (e.g. process-compose).

- Devenv provides configuration for lots of git hooks, no real similar
  integration in Flox.

- Devenv "tasks" allow you to hook into the lifecycle of the environment more
  precisely (tasks are run when the environment is started asynchronously).

- Composition

  - Flox environments are composed additively.  You run "flox activate"
    multiple times, e.g. once to install frontend packages and hooks for the
    frontend, once to install backend packages and hooks.

    This isn't really how devenv works.  In devenv, an environment is composed
    from a single devenv.nix, although you can break it into bits using
    "profiles" which are thin wrappers around Nix conditions (e.g. frontend and
    backend).

  - Flox seems to believe that people imperatively find problems and
    solve them without switching context out of the flow of the commands
    they're excuting in the shell, and seem to believe that people ideally
    compose things this way.  I don't personally work like this, so it's not
    much help to me; I chose Nix for a reason, and that reason was that it
    wasn't at all imperative; instead it was always via a config file that I
    actually edited and owned.

  - You inherit guru code in Flox via an environment, much as you do when you
    attempt to compose a Docker environment from multiple Dockerfiles
    (e.g. FROM python:3 AS base), although it's not really a perfect analogy.
    In devenv, you inherit guru code in devenv via a "language" or a "service"
    and compose the environment yourself from them.  I prefer the latter
    because there is exactly one source of truth.  The compose an environment
    from several others model doesn't really fit my brain, but it might fit
    yours.

- Concerns about lockin and freshness make me most uncomfortable about Flox:

  - The backing services for "flox search" and "flox install" (I think these
    are referred to as the "flox catalog") are provided solely by Flox the
    company.  If Flox-the-company goes away, someone else will need to stand
    these services up.  Devenv just uses nixpkgs, and there are well understood
    ways to set up a nixpkgs cache.  The flox catalog code is probably open
    source, but I don't know anyone who would know how to stand one up.

  - The flox catalog needs to ingest nixpkgs and reindex it to be consumable by
    the flox CLI, so there is bound to be some delay between a package being
    available in Nix and one being available in Flox.

  - Binary cached versions only via the catalog?  In devenv, as in Nix, I can
    use a source-only derivation for anything I like as long as I am willing to
    recompile it.  This doesn't appear possible in Flox.

  - FloxHub.  Something like DockerHub.  You upload your environment configs to
    it.  Your team shares these.  It's the monetization strategy for Flox.
    
  - Devenv hews much closer to the Nixy way of doing things, and because
    environments are not composed like Flox, there just is no need or
    oppportunity for a DevenvHub.  It's all just Git.

Unknown
_______

- Containerization?

Conclusion
__________

- Flox is slicker, more marketing polish (Flox is more SF, Devenv is more
  Lubjiana).

- Flox is better at hiding Nix, and better at allowing you to easily choose
  package versions.  Flatter learning curve.

- Devenv, because it doesn't attempt to hide Nix to the same extent, is more
  powerful, and likely more futureproof.

- If I think I'm on a team that won't accept seeing any Nix at all, I might
  bust out Flox.  Otherwise it's always gonna be devenv.
  
- But both are a step forward!
