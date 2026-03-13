# nixos-iot

Declarative IoT platform built on NixOS. Every device is defined as a NixOS configuration. A single `nix build` produces a reproducible SD card image with the OS, services, and application code baked in. Change a config option, rebuild in seconds, flash, boot -- done. No manual provisioning, no imperative state, no configuration drift across devices.

Currently running on Raspberry Pi 5 devices collecting air quality data via SDS011 sensors, with Prometheus metrics exposed for monitoring.

## Repository structure

```
nixos-iot/
  apps/
    airdata/          Go daemon: SDS011 particulate matter Prometheus exporter
  hosts/
    airsensor/        RPi5 running the airdata sensor service
    gateway/          RPi5 WireGuard VPN gateway
  infra/
    builder/          On-demand ARM build servers (Hetzner Cloud, Pulumi/TS)
  keys/               SSH authorized keys baked into every image
  flake.nix           Ties it all together
  justfile            Build, flash, and infra commands
```

## How it works

Each device has a NixOS configuration under `hosts/` that declares its entire system state: packages, services, users, networking. The flake composes these with [raspberry-pi-nix](https://github.com/nix-community/raspberry-pi-nix) to produce compressed SD card images.

Application code lives under `apps/`. Each app is a self-contained Nix flake that provides both a package and a NixOS module. The top-level flake pulls them in as local path inputs -- app changes and device config changes land in the same commit.

Since the target is `aarch64-linux`, builds are offloaded to remote ARM builders. A local RPi5 works out of the box. For faster builds or when no Pi is available, `infra/builder/` spins up Hetzner Cloud ARM instances on demand.

## Hosts

| Host | Purpose |
|------|---------|
| `gateway` | Network gateway with WireGuard VPN |
| `airsensor` | Air quality station running the airdata Prometheus exporter |

Both share: RPi5 (BCM2712), NetworkManager, SSH with key-only auth, passwordless sudo.

## Quick start

```bash
# build an image
just build-airsensor

# flash to SD card
just flash airsensor /dev/sdX

# boot the Pi -- SSH in, service is running
ssh iot@airsensor
systemctl status airdata
curl localhost:8000/metrics
```

## Building images

```bash
just build-gateway      # results/gateway/sd-image/*.img.zst
just build-airsensor    # results/airsensor/sd-image/*.img.zst
```

Builds use remote ARM builders. The default is a local RPi5 reachable via `ssh://rpi5` (configure in `~/.ssh/config`). Add more builders:

```bash
echo 'ssh://nix@other-host aarch64-linux' | just add-builder
```

## Cloud builders

For faster builds or CI, spin up ARM instances on Hetzner Cloud:

```bash
just builder-up         # provision ARM server (~3 min including nix install)
just builder-status     # show running builders as JSON

# add to local builder pool
just builder-status | jq -r '.[] | "ssh://\(.user)@\(.host) \(.arch)"' | just add-builder

just build-airsensor    # now uses both local Pi and cloud builder

just builder-down       # tear down when done
```

Builder config lives in `infra/builder/Pulumi.dev.yaml`. Scale by changing `count` or `serverType`:

```yaml
config:
  nix-builder:builders:
    aarch64:
      serverType: cax11    # 2 vCPU, 4 GB -- 0.006 EUR/h
      cores: 2
      count: 1
```

## Adding a new device

1. Create `hosts/<device>/configuration.nix`
2. Add `nixosConfigurations.<device>` in `flake.nix`
3. Add `build-<device>` recipe to the justfile

## Adding a new app

1. Create `apps/<name>/` with source code, `flake.nix`, and `module.nix`
2. Add the app as a flake input: `<name>.url = "path:./apps/<name>"`
3. Import the NixOS module in the target host's flake config

## Why NixOS for IoT

The traditional embedded Linux stack (Yocto/Buildroot) gives fine-grained control at the cost of complexity: custom BSP layers, BitBake recipes, hours-long builds, and a toolchain few developers want to touch.

NixOS takes a different approach. The entire system is declared in Nix and built from nixpkgs -- the same package set used on desktops and servers. This means:

- **Fast iteration**: config changes rebuild only what changed. Seconds, not hours.
- **Reproducibility**: same flake lock, same image. No configuration drift across devices.
- **One toolchain**: Nix modules work the same for servers, desktops, and embedded targets. No separate recipe language.
- **100k+ packages**: nixpkgs has everything. No need to write custom recipes for common software.
- **Atomic rollbacks**: every config change is a new generation. Roll back by booting the previous one.

The tradeoff is image size (larger than a minimal Yocto build) and less control over low-level kernel/bootloader details. For IoT devices with SD cards and network connectivity, that tradeoff is well worth it.

## Documentation

- [Getting started](docs/getting-started.md) -- prerequisites, building, flashing, first boot
- [Architecture](docs/architecture.md) -- how flakes, modules, builders, and images fit together

## Background

This project grew out of [years of building embedded Linux systems](https://charemma.de) with Yocto, Buildroot, and custom BSP stacks in regulated environments (medical devices, industrial automation). These tools earn their place in large-scale, safety-certified projects where fine-grained control over every binary matters. But for IoT -- where you want fast iteration, reproducible deployments, and a toolchain that doesn't require a dedicated build team -- they are overkill. NixOS fills that gap.
