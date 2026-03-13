# NixOS IoT Platform

![NixOS](https://img.shields.io/badge/NixOS-Flakes-blue?logo=nixos)
![Platform](https://img.shields.io/badge/Platform-IoT-green)
![Architecture](https://img.shields.io/badge/Architecture-Edge%20Platform-purple)
![Status](https://img.shields.io/badge/status-experimental-orange)

A reference platform exploring how **NixOS and Nix Flakes** can be used
to build reproducible IoT systems.

The repository demonstrates a **platform engineering approach for
embedded Linux devices** combining system configuration, applications
and developer environments in a single declarative codebase.

---

# Repository Structure

```
apps/       application workloads (Go daemons, services)
hosts/      concrete IoT device definitions (airsensor, gateway)
infra/      infrastructure and deployment (cloud builders)
keys/       SSH authorized keys baked into every image
docs/       architecture and workflow documentation
```

---

# Architecture

```
Developer
   │
   ▼
DevShell
   │
   ▼
Applications
   │
   ▼
NixOS Modules
   │
   ▼
Host Definition
   │
   ▼
Device Image
   │
   ▼
IoT Device
```

---

# Quick Start

```bash
# install nix (if not present)
curl -L https://nixos.org/nix/install | sh

# e.g. build the airsensor sd card image
just airsensor::build

# flash to SD card
just airsensor::flash /dev/sdX

# boot the Pi, SSH in
ssh iot@airsensor
systemctl status airdata
curl localhost:8000/metrics
```

---

# Documentation

- [Getting started](docs/getting-started.md) -- prerequisites, building, flashing, first boot
- [Architecture](docs/architecture.md) -- layered design, modules, products
- [Development workflow](docs/development-workflow.md) -- day-to-day iteration
- [Nix vs Yocto](docs/nix-vs-yocto.md) -- side-by-side comparison

---

Author: [Charalambos Emmanouilidis](https://charemma.de)
