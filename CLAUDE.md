# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A NixOS-based IoT platform for Raspberry Pi and other embedded boards. Uses Nix Flakes to declaratively define complete system images from a single codebase covering system config, applications, and infrastructure. This is a reference implementation, not a production-ready setup.

## Build commands

All commands use `just` with module namespacing (`just <module>::<recipe>`). Enter the dev shell first with `nix develop` (or `direnv allow`) -- works on Linux and macOS natively.

```bash
# list all available recipes
just

# build SD card image for a host
just airsensor::build
just gateway::build

# flash image to SD card
just airsensor::flash /dev/sdX

# deploy config update to running device over SSH (builds on-device, no reflash)
just airsensor::deploy
just gateway::deploy

# cloud builder workflow (Pulumi, Hetzner Cloud)
just builder::up                # provision ARM builders
eval $(just builder::env)       # export NIX_BUILDERS for nix to use
just airsensor::build           # build uses cloud builder automatically
just builder::down              # tear down when done

# other builder recipes
just builder::status   # show running builders as JSON
just builder::plan     # preview Pulumi changes

# airdata app (Go) -- not registered as root justfile module, run from apps/airdata/
cd apps/airdata
just build             # go build
just test              # go test ./...
just lint              # golangci-lint run ./...
just run               # build + run locally
just nix-build         # nix build
```

## Architecture

**Flake structure**: The root `flake.nix` defines two `nixosConfigurations` (airsensor, gateway), both targeting `aarch64-linux`. A `sharedModules` list composes the common modules, each product appends its own config on top.

**Shared modules** in `modules/`:

| Module | Purpose |
|--------|---------|
| `bsp-rpi.nix` | Board Support Package for RPi 5 (board variant, filesystem). Analogous to a Yocto BSP layer. |
| `base.nix` | Hardware-agnostic system defaults (networking, locale, SSH, flakes) |
| `core.nix` | Common tools for debugging and demo (vim, htop, curl, tmux) |
| `user.nix` | iot user, group, passwordless sudo |
| `authorized-keys.nix` | SSH keys for the iot user |

New boards get their own `bsp-<board>.nix`. `base.nix`, `core.nix`, `user.nix` are board-independent and reusable across any product.

**Application pattern**: Apps live in `apps/` as independent flakes with their own `flake.nix`. Each app exposes a `nixosModules.default` that the root flake imports. The module (`module.nix`) defines `services.<name>` options and a hardened systemd unit. The root flake follows the app's nixpkgs via `inputs.follows`.

**Cross-compilation**: Development happens on x86_64 (Linux or macOS). Image builds are delegated to aarch64-linux remote builders over SSH. The default builder is `ssh://rpi` (configured in the root justfile's `_builders` recipe). Setting `NIX_BUILDERS` overrides the default (this is what `just builder::env` does for cloud builders). Cloud builders are ephemeral ARM servers on Hetzner Cloud, managed via Pulumi in `infra/builder/`.

**Deploy vs build**: `deploy` runs `nixos-rebuild switch` on the target device itself (`--build-host iot@<host>`), so it doesn't need a cross-compilation builder. `build` produces a full image and requires an ARM builder.

**Product configs**: Each product in `products/<name>/configuration.nix` contains only host-specific settings (hostname, which services to enable). Everything else comes from shared modules.

**Justfile modules**: The root justfile only loads submodules via `mod`. Per-host justfiles use `set fallback := true` to inherit shared recipes like `_builders` from the parent.

## Key conventions

- All images produce compressed SD card images at `results/<host>/sd-image/*.img.zst`
- The `iot` user is the standard user on all devices (key-only SSH, passwordless sudo)
- App flakes are consumed as path inputs (`path:./apps/<name>`) by the root flake
- When Go dependencies change in an app, update the `vendorHash` in its `flake.nix` (nix build will fail with a hash mismatch and tell you the correct hash)
- When adding a new app: create `apps/<name>/flake.nix` with a `nixosModules.default`, add it as an input in root `flake.nix`, enable it in the host config
- When adding a new product: create `products/<name>/configuration.nix`, add a `nixosConfigurations.<name>` in root `flake.nix`, create `products/<name>/justfile` with build/flash/deploy recipes, register it as a `mod` in root justfile
- When adding a new board: create `modules/bsp-<board>.nix`, swap it into the product's module list in `flake.nix`
