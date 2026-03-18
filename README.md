# Building an IoT Platform with NixOS

![NixOS](https://img.shields.io/badge/NixOS-Flakes-blue?logo=nixos)
![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi%205-aarch64-c51a4a?logo=raspberrypi)
![IaC](https://img.shields.io/badge/IaC-Pulumi-8a3391?logo=pulumi)
![Status](https://img.shields.io/badge/status-reference%20implementation-blue)

A reference implementation exploring how **NixOS and Nix Flakes** can be
used to build a platform for IoT and edge devices. The repository
demonstrates a **platform engineering approach for embedded Linux**: shared
modules and applications composed into concrete product definitions, built
reproducibly with full supply chain control.

---

# Why NixOS for IoT?

Traditional embedded Linux stacks (Yocto, Buildroot) are powerful but complex.
NixOS brings reproducible builds, atomic updates and a declarative configuration
model -- properties that map well to managing fleets of devices. This project
explores that idea. For a detailed comparison, see
[Nix vs Yocto](docs/nix-vs-yocto.md).

The same flake that defines device images also provides the development
environment. `nix develop` (or direnv) gives every contributor an identical
shell with all required tools -- on macOS, Linux and WSL, natively, without
Docker or devcontainers.

---

# Platform Concept

The platform separates reusable building blocks from concrete product
definitions. Each product owns its own `flake.nix` and declares which
platform modules and applications it needs. Multiple products can share
the same app or module.

| Layer | What | Where |
|-------|------|-------|
| Applications | Product-specific daemons and services | `apps/` |
| Platform modules | Shared system configuration (networking, users, BSP) | `modules/` |
| Products | Concrete device definitions composed from the above | `products/<name>/` |
| Infrastructure | Ephemeral ARM build servers | `infra/` |

Each product has its own `flake.nix` that imports only what it needs.
The root flake re-exports all product configurations. This gives each
product team full control over its dependencies.

---

# Products

| Product | Role | App | Target |
|---------|------|-----|--------|
| **sentinel-node** | Edge security monitor | sentinel (Rust, libpcap) | x86 VM / RPi 5 |
| **airsensor** | Air quality sensor | airdata (Go, SDS011) | RPi 5 |
| **gateway** | Network gateway | WireGuard | RPi 5 |

---

# Try It: Sentinel Node

The sentinel-node is the easiest way to try this project. It builds and
runs as a QEMU VM on any x86 Linux machine -- no Raspberry Pi, no cloud
builder, no special hardware needed.

```bash
# enter the dev shell
nix develop

# build the VM (first build takes a while, subsequent builds are cached)
just sentinel-node::build-vm

# start the VM (bridged to your local network)
just sentinel-node::vm

# find the VM's IP
sudo arp-scan -l -I br0 | grep 52:54:00

# query metrics
curl <vm-ip>:9090/metrics

# view live security events
ssh iot@<vm-ip> journalctl -u sentinel -f -o cat | grep '^{' | jq .
```

The VM boots into a hardened NixOS system with:
- passive network traffic capture (libpcap, promiscuous mode)
- Prometheus metrics (packets, bytes, DNS queries, TCP connections, unique IPs)
- structured JSON event log (DNS queries, connection attempts)
- default-deny firewall, kernel hardening, audit logging
- no debug tools, no interactive console (SSH-only)

For the full SD card image (Raspberry Pi), see
[sentinel-node/README.md](products/sentinel-node/README.md).

---

# Repository Structure

```
apps/               product applications, packaged as independent Nix flakes
  sentinel/           network security monitor (Rust)
  airdata/            SDS011 particulate matter exporter (Go)
products/           product definitions, each with its own flake.nix
  sentinel-node/      edge security monitor (hardened, minimal)
  airsensor/          air quality sensor node
  gateway/            network gateway
modules/            shared NixOS platform modules (BSP, base, user management)
  flake.nix           exports all shared modules as a flake
infra/              declarative build infrastructure
  builder/            ephemeral ARM builders on Hetzner Cloud (Pulumi)
docs/               architecture and workflow documentation
```

---

# Build Infrastructure

For products targeting Raspberry Pi (`aarch64-linux`), builds are delegated
to remote ARM builders over SSH. The `infra/builder/` directory contains a
Pulumi project that provisions ARM servers on Hetzner Cloud on demand:

```bash
just builder::up              # provision ARM instance
eval $(just builder::env)     # load builder env vars
just airsensor::build         # build image (compiled on the ARM builder)
just builder::down            # tear down instance
```

No permanent build server needed. A `cax11` instance costs about 0.006 EUR/h.

The sentinel-node VM target (`just sentinel-node::build-vm`) builds natively
on x86 and does not require a remote builder.

## Binary cache

The project uses [Attic](https://github.com/zhaofengli/attic) as a
self-hosted Nix binary cache. After building, push the results so
future builds (and other machines) can reuse them:

```bash
just sentinel-node::publish-cache
```

The sentinel-node release build enforces a strict supply chain policy:
it only pulls from the internal cache, never from cache.nixos.org. This
ensures full provenance over every artifact in the image.

---

# Documentation

- [Getting started](docs/getting-started.md) -- prerequisites, building, flashing
- [Dev machine setup](docs/dev-machine-setup.md) -- builder key, SSH config, how the Nix daemon connects
- [Remote builder setup](docs/remote-builder-setup.md) -- setting up a Pi as a Nix remote builder
- [Architecture](docs/architecture.md) -- layered design, modules, products
- [Nix vs Yocto](docs/nix-vs-yocto.md) -- side-by-side comparison

---

Author: [Charalambos Emmanouilidis](https://charemma.de)
