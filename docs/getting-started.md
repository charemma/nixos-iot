# Getting started

This guide walks through setting up the build environment, building your first SD card image, and booting a Raspberry Pi 5 with it.

## Prerequisites

You need a Linux or macOS machine with:

- **Nix** (2.18+) with flakes enabled
- **An ARM builder** for cross-compilation (see [remote builders](#remote-builders) below)
- **An SD card** and a way to write to it (Linux for `dd`, or use a flashing tool on macOS)

### Installing Nix

If you don't have Nix yet:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable flakes by adding to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### Entering the dev shell

The repo provides a Nix dev shell with all required tools (just, pulumi, node):

```bash
cd nixos-iot

# option A: direnv (recommended)
direnv allow

# option B: manual
nix develop
```

## Building an image

```bash
just airsensor::build
```

This evaluates the NixOS configuration for the `airsensor` host and produces a compressed SD card image at `results/airsensor/sd-image/*.img.zst`.

The build targets `aarch64-linux`. Since most development machines are x86_64, the actual compilation is delegated to a remote ARM builder over SSH. Nix handles this transparently -- you run the command locally, the heavy lifting happens on the builder.

## Remote builders

Nix needs at least one aarch64-linux builder to compile RPi5 images. There are three options, from simplest to most flexible:

### Option 1: Use an existing Raspberry Pi

If you have a Pi running NixOS or Nix (on any distro), point to it via SSH config:

```
# ~/.ssh/config
Host rpi5
    HostName 192.168.1.x
    User iot
```

The justfile uses `ssh://rpi5` as the default builder. Make sure the remote user is in `trusted-users` in the Pi's nix config.

### Option 2: Use binfmt/QEMU emulation

Add this to your NixOS config and rebuild:

```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

This emulates ARM on your x86 CPU. It works but is significantly slower than native builders (~10-20x). Fine for small changes, painful for full image builds.

### Option 3: Spin up a cloud builder

The `infra/builder/` directory contains a Pulumi project that provisions ARM servers on Hetzner Cloud:

```bash
# one-time setup
cd infra/builder
npm install
pulumi stack init dev
pulumi config set hcloud:token --secret

# spin up
cd ../..
just builder::up

# add to builder pool
just builder::status | jq -r '.[] | "ssh://\(.user)@\(.host) \(.arch)"' | just builder::add

# tear down when done
just builder::down
```

A `cax11` instance (2 vCPU ARM, 4 GB RAM) costs about 0.006 EUR/h. Builders are ephemeral -- spin up before a build session, tear down after.

## Flashing the SD card

Insert the SD card and identify the device:

```bash
lsblk
```

Look for the SD card -- typically the smallest block device that just appeared (e.g. `/dev/sdb`). Make absolutely sure you have the right device.

```bash
just airsensor::flash /dev/sdX
```

This decompresses the image and writes it directly. There is no confirmation prompt -- double-check the device path.

Alternatively, flash manually:

```bash
zstdcat results/airsensor/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

Eject the card, insert it into the Pi, and power on.

## First boot

The Pi boots into NixOS with:

- SSH enabled on port 22
- A `iot` user with key-only auth (keys from `modules/authorized-keys.nix`)
- Passwordless sudo
- The device-specific services running (e.g. airdata exporter on the airsensor)

```bash
ssh iot@<pi-ip>
systemctl status airdata    # on airsensor
curl localhost:8000/metrics # prometheus endpoint
```

The IP depends on your network. Check your router's DHCP leases or use `nmap -sn 192.168.1.0/24` to find it.

## Making changes

Edit the host config or app code, then rebuild and reflash:

```bash
# change something in products/airsensor/configuration.nix or apps/airdata/
just build-airsensor
just airsensor::flash /dev/sdX
```

Only what changed gets rebuilt -- Nix caches everything else. A config-only change (no new packages) takes seconds to build.

For iterating on the app code without reflashing, you can also build and test the app directly:

```bash
nix build ./apps/airdata
./result/bin/airdata
```
