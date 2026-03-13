# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A NixOS-based IoT platform for Raspberry Pi 5 devices. Uses Nix Flakes to declaratively define complete system images (SD card images) from a single codebase covering system config, applications, and infrastructure.

## Build commands

All commands use `just` with module namespacing (`just <module>::<recipe>`). Enter the dev shell first with `nix develop` (or `direnv allow`).

```bash
# list all available recipes
just

# build SD card image for a host
just airsensor::build
just gateway::build

# flash image to SD card
just airsensor::flash /dev/sdX

# deploy config update to running device over SSH
just airsensor::deploy
just gateway::deploy

# cloud builder management (Pulumi, Hetzner Cloud)
just builder::init     # npm install
just builder::up       # provision ARM builders
just builder::down     # tear down builders
just builder::status   # show running builders
just builder::plan     # preview changes

# airdata app (Go)
just airdata::build    # go build (note: no module registered yet, run from apps/airdata/)
cd apps/airdata
just build             # go build
just test              # go test ./...
just lint              # golangci-lint run ./...
just run               # build + run locally
just nix-build         # nix build
```

## Architecture

**Flake structure**: The root `flake.nix` defines two `nixosConfigurations` (airsensor, gateway), both targeting `aarch64-linux`. Each composes `raspberry-pi-nix` hardware modules with host-specific config from `hosts/`.

**Application pattern**: Apps live in `apps/` as independent flakes with their own `flake.nix`. Each app exposes a `nixosModules.default` that the root flake imports. The module (`module.nix`) defines `services.<name>` options and a hardened systemd unit. The root flake follows the app's nixpkgs via `inputs.follows`.

**Cross-compilation**: Development happens on x86_64-linux. Builds are delegated to aarch64-linux remote builders over SSH. The default builder is `ssh://rpi5` (configured in justfiles via `_builders` recipe). Additional builders can be registered in `builders.conf` at the repo root. Cloud builders can be spun up ephemerally via `infra/builder/` (Pulumi + Hetzner Cloud, TypeScript).

**Host configs**: Each host in `hosts/<name>/configuration.nix` sets hardware board (`bcm2712` for RPi5), networking, users, and which app modules to enable. SSH keys from `keys/authorized_keys` are baked into every image.

**Justfile modules**: The root justfile only loads submodules via `mod`. Per-host justfiles use `set fallback := true` to inherit shared recipes like `_builders` from the parent.

## Key conventions

- All images produce compressed SD card images at `results/<host>/sd-image/*.img.zst`
- The `iot` user is the standard user on all devices (key-only SSH, passwordless sudo)
- App flakes are consumed as path inputs (`path:./apps/<name>`) by the root flake
- When adding a new app: create `apps/<name>/flake.nix` with a `nixosModules.default`, add it as an input in root `flake.nix`, enable it in the host config
- When adding a new host: create `hosts/<name>/configuration.nix`, add a `nixosConfigurations.<name>` in root `flake.nix`, create `hosts/<name>/justfile` with build/flash/deploy recipes, register it as a `mod` in root justfile
