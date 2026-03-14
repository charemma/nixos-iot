# Getting started

## Prerequisites

- **Nix** (2.18+) with flakes enabled
- **An aarch64-linux builder** reachable via SSH (see [dev machine setup](dev-machine-setup.md) and [remote builder setup](remote-builder-setup.md))
- **An SD card** and a way to write to it

## Dev shell

The repo provides a Nix dev shell with all required tools (just, pulumi, node):

```bash
# option A: direnv (recommended)
direnv allow

# option B: manual
nix develop
```

## Building an image

```bash
just airsensor::build
```

This produces a compressed SD card image at `results/airsensor/sd-image/*.img.zst`. The build targets `aarch64-linux` and is delegated to a remote ARM builder over SSH -- Nix handles this transparently.

## Flashing

```bash
just airsensor::flash /dev/sdX
```

Double-check the device path -- there is no confirmation prompt.

## First boot

The Pi boots into NixOS with SSH enabled, an `iot` user with key-only auth (keys from `modules/authorized-keys.nix`) and passwordless sudo.

```bash
ssh iot@<pi-ip>
systemctl status airdata    # on airsensor
curl localhost:8000/metrics
```

## Deploying updates

For changes that don't require a reflash:

```bash
just airsensor::deploy
```

For app-only iteration without deploying to a device:

```bash
nix build ./apps/airdata
./result/bin/airdata
```
