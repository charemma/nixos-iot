# Architecture

This document explains the key concepts and how the pieces fit together.

## Overview

```
                                    +------------------+
  just build-airsensor              |  Remote Builder  |
          |                         |  (RPi5 / Cloud)  |
          v                         +--------+---------+
  +-------+--------+                         ^
  |   Nix Flake    |   delegates build via   |
  |                +-------------------------+
  |  - nixpkgs     |        SSH
  |  - rpi-nix     |
  |  - airdata     |
  +-------+--------+
          |
          v
  results/airsensor/sd-image/*.img.zst
          |
          v
    just flash airsensor /dev/sdX
          |
          v
      [SD Card] --> [Raspberry Pi 5]
```

## Nix Flakes

A flake is a self-contained, reproducible Nix project. The `flake.nix` at the repo root declares:

- **Inputs**: pinned dependencies (nixpkgs, raspberry-pi-nix, apps)
- **Outputs**: what the flake produces (NixOS configurations, dev shells)

The `flake.lock` pins every input to an exact git revision. This guarantees that the same lock file always produces the same image, regardless of when or where you build it.

To update dependencies:

```bash
nix flake update
```

This fetches the latest versions and updates the lock file. Review, test, commit.

## NixOS configurations

Each host under `hosts/` is a NixOS configuration -- a declarative description of the entire system. Everything that ends up on the device is specified here: packages, services, users, networking, kernel modules.

NixOS evaluates the configuration and produces a complete system closure: every file, every binary, every config file that makes up the running system. Nothing is implicit.

The configuration is composed from modules:

```nix
modules = [
  raspberry-pi-nix.nixosModules.raspberry-pi   # RPi5 kernel, firmware, device tree
  raspberry-pi-nix.nixosModules.sd-image        # SD card image builder
  airdata.nixosModules.default                   # airdata service (from apps/)
  ./hosts/airsensor/configuration.nix            # device-specific config
];
```

Each module can define options (interface) and config (implementation). This is how the airdata app exposes `services.airdata.enable` -- the host config sets it to `true`, the module handles everything else.

## Apps as flake inputs

Application code lives under `apps/`. Each app is a standalone Nix flake that provides:

- A **package** (the compiled binary)
- A **NixOS module** (systemd service definition, options, hardening)

The top-level flake references apps as local path inputs:

```nix
airdata.url = "path:./apps/airdata";
```

This means changes to app code are immediately visible to the image build -- no version bumping, no publishing to a registry. In CI, the same flake lock ensures reproducibility.

## Remote builders

NixOS images for RPi5 target `aarch64-linux`. Building on an x86_64 machine requires cross-compilation, which Nix solves through remote builders.

When `nix build` encounters a derivation for a foreign architecture, it delegates the build to a remote machine over SSH. The remote machine runs the Nix daemon and returns the build result. From the user's perspective, it's transparent.

The justfile assembles builders from two sources:

1. **Default**: `ssh://rpi5` -- a local Pi that's always available
2. **Extras**: `builders.conf` -- additional builders (cloud instances, CI runners)

Both are passed to `nix build --builders "builder1;builder2;..."`.

### Cloud builders

The `infra/builder/` Pulumi project provisions ephemeral ARM instances on Hetzner Cloud. These are Ubuntu VMs with Nix installed via cloud-init. They exist only during build sessions and cost fractions of a cent per hour.

This is the same pattern used in CI/CD: spin up compute, build, tear down. The difference is that developers can do it from their local machine with a single command.

## SD card images

The `raspberry-pi-nix` sd-image module produces a complete disk image:

1. Evaluates the NixOS configuration into a system closure
2. Creates an ext4 root filesystem containing the closure
3. Adds the RPi5 bootloader (firmware, device tree, kernel)
4. Compresses the result with zstd

The output is a single `.img.zst` file that can be written to an SD card with `dd`. On first boot, NixOS runs activation scripts that set up users, services, and networking as declared in the configuration.

## Adding devices

Adding a new device type follows a consistent pattern:

1. Create `hosts/<device>/configuration.nix` with the device-specific NixOS config
2. Add a `nixosConfigurations.<device>` entry in `flake.nix`
3. Add a `build-<device>` recipe to the justfile

The new device inherits the entire build and deploy pipeline. No new tooling, no new CI config -- just another configuration.
