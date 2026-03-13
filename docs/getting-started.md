# Getting started

## Prerequisites

- **Nix** (2.18+) with flakes enabled
- **An aarch64-linux builder** reachable via SSH (see [remote builder setup](#remote-builder-setup) below)
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

---

## Remote builder setup

Images target `aarch64-linux` but development typically happens on `x86_64`. Nix delegates the compilation to a remote ARM builder over SSH.

You can use any machine with Nix installed as a builder -- a Raspberry Pi, a cloud instance, etc. Alternatively, `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` on a NixOS dev machine enables QEMU emulation, which works but is significantly slower (~10-20x).

### SSH and the Nix daemon

When you run `nix build --builders "ssh://..."`, **your user does not open the SSH connection**. The nix client delegates the job to the Nix daemon, which runs as a systemd service under root. The daemon opens the SSH connection, so it uses root's SSH config and known_hosts -- not yours. A per-user `~/.ssh/config` is not enough.

The recommended setup is a dedicated build key and system-wide SSH configuration so that any user on the dev machine (including the daemon) can reach the builder without manual `/root/.ssh/` entries.

### Step by step

1. Generate a dedicated key pair for nix builds (one-time):

```bash
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_ed25519 -N "" -C "nix-builder"
```

2. Authorize the key on the builder:

```bash
sudo ssh-copy-id -i /etc/nix/builder_ed25519.pub iot@rpi5
```

3. Add system-wide SSH config on the dev machine. On NixOS, in your system configuration:

```nix
programs.ssh.matchBlocks.rpi5 = {
  hostname = "192.168.1.x";
  user = "iot";
  identityFile = "/etc/nix/builder_ed25519";
};
```

Optionally, skip host key verification for builders. This is useful when
builder host keys change frequently (reflashed devices, ephemeral cloud
instances):

```nix
programs.ssh.matchBlocks.rpi5 = {
  hostname = "192.168.1.x";
  user = "iot";
  identityFile = "/etc/nix/builder_ed25519";
  extraOptions = {
    StrictHostKeyChecking = "no";
    UserKnownHostsFile = "/dev/null";
  };
};
```

4. Make sure the builder user is in `trusted-users` in the builder's nix config.

### Cloud builders

The `infra/builder/` directory contains a Pulumi project that provisions ephemeral ARM servers on Hetzner Cloud. It uses `/etc/nix/builder_ed25519.pub` by default -- cloud instances are automatically provisioned with that key authorized.

```bash
# one-time setup
just builder::init
pulumi config set hcloud:token --secret

# spin up, build, tear down
just builder::up
just airsensor::build
just builder::down
```

A `cax11` instance (2 vCPU ARM, 4 GB RAM) costs about 0.006 EUR/h.
