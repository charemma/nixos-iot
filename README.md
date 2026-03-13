# Building an IoT Platform with NixOS

![NixOS](https://img.shields.io/badge/NixOS-Flakes-blue?logo=nixos)
![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi%205-aarch64-c51a4a?logo=raspberrypi)
![IaC](https://img.shields.io/badge/IaC-Pulumi-8a3391?logo=pulumi)
![Status](https://img.shields.io/badge/status-reference%20implementation-blue)

A reference implementation exploring how **NixOS and Nix Flakes** can be
used to build a platform for IoT products. The repository demonstrates a
**platform engineering approach for embedded Linux**: shared modules and
applications composed into concrete product definitions, built reproducibly
with ephemeral cloud infrastructure.

---

# Why NixOS for IoT?

Traditional embedded Linux stacks (Yocto, Buildroot) are powerful but complex.
NixOS brings reproducible builds, atomic updates and a declarative configuration
model -- properties that map well to managing fleets of devices. This project
explores that idea. For a detailed comparison, see
[Nix vs Yocto](docs/nix-vs-yocto.md).

---

# Platform Concept

The platform separates reusable building blocks from concrete product
definitions. Applications and NixOS modules are developed independently
and composed into product-specific configurations. Multiple products can
share the same app or module.

| Layer | What | Where |
|-------|------|-------|
| Applications | Product-specific daemons and services | `apps/` |
| NixOS modules | Shared system configuration (networking, users, tools) | `products/`, `modules/` |
| Products | Concrete device definitions composed from the above | `products/<name>/` |
| Infrastructure | Ephemeral ARM build servers | `infra/` |

Everything lives in a single repository so that changes across layers --
a new sensor driver, the NixOS module that runs it, and the host config
that enables it -- can land in a single commit.

---

# Products

| Product | Role | Key services |
|---------|------|-------------|
| **airsensor** | Air quality sensor node | airdata (SDS011 Prometheus exporter) |
| **gateway** | Network gateway | WireGuard VPN |

Both run on Raspberry Pi 5 (`bcm2712`), boot from SD card and are managed
over SSH.

---

# Repository Structure

```
apps/        product applications, packaged as independent Nix flakes
  airdata/     SDS011 particulate matter exporter (Go)
products/       product definitions, one per device
  airsensor/   air quality sensor node
  gateway/     network gateway
infra/       declarative build infrastructure
  builder/     ephemeral ARM builders on Hetzner Cloud (Pulumi, TypeScript)
modules/     shared NixOS modules included by all products
  authorized-keys.nix   SSH authorized keys for the iot user
docs/        architecture and workflow documentation
```

---

# Build Infrastructure

Images target `aarch64-linux` but development happens on `x86_64`. Builds
are delegated to remote ARM builders over SSH -- Nix handles this
transparently.

The `infra/builder/` directory contains a Pulumi project that provisions
ARM servers on Hetzner Cloud on demand. A typical CI/CD flow:

```bash
just builder::up           # provision ARM instance
just airsensor::build      # build image (compiled on the ARM builder)
just builder::down         # tear down instance
```

No permanent build server needed. A `cax11` instance costs about 0.006 EUR/h.

---

# Quick Start

```bash
# install nix (if not present)
curl -L https://nixos.org/nix/install | sh

# enter the dev shell
nix develop

# add your SSH public keys (the repo ships the author's keys)
# edit modules/authorized-keys.nix and add your key to the list

# build the airsensor SD card image
just airsensor::build

# flash to SD card
just airsensor::flash /dev/sdX

# boot the Pi, SSH in
ssh iot@airsensor
systemctl status airdata
curl localhost:8000/metrics
```

See [Getting started](docs/getting-started.md) for prerequisites and
remote builder setup.

---

# Documentation

- [Getting started](docs/getting-started.md) -- prerequisites, building, flashing, first boot
- [Remote builder setup](docs/remote-builder-setup.md) -- setting up a Pi as a Nix remote builder
- [Architecture](docs/architecture.md) -- layered design, modules, products
- [Development workflow](docs/development-workflow.md) -- day-to-day iteration
- [Nix vs Yocto](docs/nix-vs-yocto.md) -- side-by-side comparison

---

Author: [Charalambos Emmanouilidis](https://charemma.de)
