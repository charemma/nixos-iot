# Architecture

The platform follows a layered architecture where reusable NixOS modules
are composed into concrete device configurations.

```
Developer
   |
   v
DevShell (nix develop)
   |
   v
Applications (apps/)
   |
   v
NixOS Modules
   |
   v
Product Definition (products/)
   |
   v
SD Card Image
   |
   v
IoT Device
```

## Layers

**Applications** -- standalone programs (e.g. the airdata Go daemon)
packaged as Nix flakes with their own NixOS service modules.

**Product definitions** -- each host in `products/` combines hardware config,
OS settings and application modules into a complete system.

**Infrastructure** -- cloud builders in `infra/` provide remote ARM
build capacity via Hetzner Cloud.

## Key properties

- Reproducible builds -- same inputs always produce the same image
- Declarative configuration -- the entire system is defined in Nix
- Atomic updates -- deployments via `nixos-rebuild` are transactional
- Cross-compilation -- images for aarch64 built on x86_64 via remote builders
