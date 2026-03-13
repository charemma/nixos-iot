# Nix vs Yocto

## The incumbent: Yocto

[Yocto](https://www.yoctoproject.org/) is the industry standard for building
custom embedded Linux distributions. It is mature, widely adopted and backed
by a large ecosystem of BSP layers from hardware vendors.

It is also notoriously complex. Builds are slow, the layer/recipe system is
hard to reason about, and small configuration changes can have surprising
side effects across the dependency graph. Getting a working setup takes
significant effort; keeping it working across updates takes more.

## Why NixOS instead

NixOS approaches the same problem -- building a complete Linux system from
source -- with a functional build model. Every package is an isolated
function of its inputs, builds are cached by content hash, and the system
configuration is a single declarative expression.

Properties that make it compelling for IoT:

- **Same toolchain everywhere** -- `nix develop` gives developers the exact
  same environment that produces the production image. No divergence between
  "works on my machine" and "works on the device".
- **Fast iteration** -- only what changed gets rebuilt. A config-only change
  takes seconds, not the minutes-to-hours typical of full Yocto builds.
- **Atomic updates** -- `nixos-rebuild switch` on a running device is
  transactional. If something fails, the previous generation is still
  bootable. No bricked devices from partial updates.
- **Composable modules** -- NixOS modules snap together declaratively.
  Enabling a service is `services.foo.enable = true`, not a chain of
  recipes, bbappends and layer priorities.
- **Reproducibility via lockfiles** -- `flake.lock` pins every input.
  The same commit always produces the same image, on any machine.

## Tradeoffs

NixOS is not without friction:

- **Learning curve** -- the Nix language and module system take time to
  internalize. The documentation has gaps, especially for embedded use cases.
- **Smaller ecosystem** -- no vendor BSP layers like Yocto has. Hardware
  support depends on upstream kernel and community projects like
  `raspberry-pi-nix`.
- **Less industrial adoption** -- fewer production deployments, fewer
  battle-tested patterns for fleet management at scale.

These are real costs. But once past the learning curve, the day-to-day
experience is significantly better: changes are safe, builds are fast,
and the entire system fits in your head as a single expression.

Yocto feels like taming a beast. Nix feels like building with Lego.

## Scope of this project

This repository is a reference implementation, not a production-ready
platform. A real product build would need additional pieces, for example:

- **Private binary cache** -- production builds should push to and pull from
  a self-hosted cache (e.g. [Attic](https://github.com/zhaofengli/attic) or
  [Cachix](https://www.cachix.org/)) rather than relying on the public
  `cache.nixos.org`.
- **Custom hardware** -- this project uses the Raspberry Pi 5 which has
  solid community support via `raspberry-pi-nix`. Exotic or vendor-specific
  boards can be tricky to integrate since, unlike Yocto, hardware vendors
  rarely ship NixOS support. Check the
  [nixpkgs platform support tiers](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md)
  and the [list of supported platforms](https://nixos.org/manual/nix/stable/installation/supported-platforms)
  to gauge how well a target architecture is covered.
