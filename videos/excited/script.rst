NixOS 39: Why You Should Maybe Be Excited About NixOS
=====================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

I think people should be excited about NixOS.  Or at least not dismissive.  I
can explain to you why I think this.

I've been using NixOS for a little over a month.  I had no intention of
creating *two* videos about it, let alone 39 of them.  It was just organic
happenstance.  I have converted five systems in my place to NixOS from various
other distributions.  The only thing that is left is really a Raspberry Pi that
runs my front door unlock, and that will likely get converted too in time.

This is mostly because I don't feel like I'm wasting my time with NixOS.  I
don't mind spending seemingly arbitrary amounts of time to create and maintain
a shared, repeatable configuration.  Here's why:

- I am not a smart man.
  
- My systems all have the same set of installed programs.

- If I need to, I can deviate from the shared norm for just one system.

- System configuration becomes a programming exercise rather than an
  administration chore.  I am comfortable with programming exercises, but I
  hate adminstrative chores.

- The integration between the language, the package manager, and the
  operating system means I am not required to invent much.  This is not the
  same of systems like Puppet or Ansible.

- I can share my system configuration with others in a meaningful, executable
  way.

- Stopping a rebuild in the middle will not result in a totally arbitrarily
  configured system.

This feature is a virtuous cycle.  Because I don't feel like I'm wasting my
time, I tend to get to the bottom of issues and fix them at the root.  Because
once it's fixed in my Nix configuration, it's fixed.  Everywhere.  Success more
often seems possible than impossible, which is a game of inches.  Here are some
concrete examples:

- I can bring up a new system with the vast majority of my required
  customizations in 20 minutes because my config is version controlled.  It's
  a copy-paste-edit thing.

- I can reinstall a system in that amount of time delta time for backup and
  restore of the homedir.

- My systems are always available remotely: local name resolution and ssh
  config are shared.

- I can print from any system.

- I can shut the lid on laptops connected to external monitors and they don't
  sleep.

- I can shut the lid on laptops not connected to external monitors and they
  do sleep.

- I can carry an external drive around that is ZFS-formatted (and encrypted)
  and mount it on any system.

- Once I supply credentials, I can send and receive Keybase messages on any
  system.

- I can use my Roland RC-505 on any system (it requires a kernel patch).

- I can use an old build of a package, reproducibly built years ago, to work
  around bitrot.

Technology will only get you so far: another abstraction layer on top of Ubuntu
(e.g. Ansible) might get you some of these benefits.  But NixOS also somehow
happens to have an excellent community, the likes of which I've not witnessed
in many other places.

- Unreal politeness, humility, and thoroughness on Discourse, Matrix, IRC,
  and GitHub.

- Vanishingly small numbers of sightings of bureaucrats, trolls, "influencers",
  or condescending know-it-alls.  This may be because if you are one of these,
  it appears that you are basically ignored, perhaps after one warning.

- Everyone is smarter than I am.  They are also recognizably human.

- Very few people in the community are cynical about NixOS.  Or, if they are,
  they are good-natured about it.

- People that I respect, know, and like, and whom deeply understand building
  systems are already involved.
    
NixOS has a revolutionary paradigm.

- Ground-up rethink of UNIX (or at least repurposing of UNIX) in many
  fundamental ways.

- The emperor has no clothes.  E.g. the LSB is kinda nonsense.
  One-package-to-rule them all is kinda nonsense.

- But it manages, currently, to bridge the gap, pretending to be just another
  geeky Linux distro.

- In reality, it is a wolf in sheep's clothing.  It is a one-way street.  Once
  you use it, you cannot go back, at least if you give it a fair shake.
  
NixOS will have some challenges.

- The community will change.  Popularity has its costs.

- There will be a temptation to impose backwards incompatibilities.
  Likewise, there will bne a temptation to avoid them arbitrarily.  Despite
  more users, development will slow to carry around legacy. But if it
  doesn't, the old users will revolt.  It is a tightrope.

- There will be pressure to integrate the various layers of Nix into one
  single layer (e.g. replace shell scripts with new Nix language constructs).
  This, IMO, is probably a bad idea, but who knows.

- The documentation is a bit of a mess.  Introspectability could be better.

But for now, I think we should celebrate.  This might be the best it's going to
get.  If it gets any better, it's a mitzvah.
