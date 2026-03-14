# Dev machine setup

How to configure your development machine for cross-compiling
aarch64-linux images using Nix remote builders.

## How Nix remote builds work

When you run `just airsensor::build`, the build recipe passes `--builders`
to `nix build`. This tells Nix to delegate aarch64-linux derivations to
a remote machine over SSH.

The important thing to understand: **the Nix daemon handles the SSH
connection, not your user session.** On a multi-user Nix installation
(the default on NixOS), `nix build` is a client that talks to the Nix
daemon via a Unix socket. The daemon runs as root under systemd. When it
needs to connect to a remote builder, it opens the SSH connection as root.

This means:

- Root's SSH config applies, not `~/.ssh/config`
- The SSH identity file must be readable by root
- Host key verification happens from root's perspective
- Environment variables like `NIX_SSHOPTS` set in your shell do not
  reach the daemon

## 1. Generate a dedicated builder key

All remote builders (local Pi, cloud instances) share a single key pair
stored in `/etc/nix/`. This location is readable by the daemon (root)
and survives user profile changes.

```bash
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_ed25519 -N "" -C "nix-builder"
```

This creates:
- `/etc/nix/builder_ed25519` (private key, `600 root:root`)
- `/etc/nix/builder_ed25519.pub` (public key, `644 root:root`)

The private key is only readable by root, which is correct -- the daemon
runs as root and is the only process that needs it.

## 2. System-wide SSH config

Since the daemon connects as root, SSH configuration must be system-wide.
A per-user `~/.ssh/config` entry will not work for builds.

### NixOS

Add to your system configuration (e.g. in a module):

```nix
programs.ssh.extraConfig = ''
  Host rpi
    HostName 192.168.1.x
    User <your-user>
    IdentityFile /etc/nix/builder_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
'';
```

`StrictHostKeyChecking no` is useful when the Pi gets reflashed regularly
and its host key changes. For a stable builder, you can omit this and
accept the key once.

Rebuild with `sudo nixos-rebuild switch`.

### macOS / nix-darwin

Same concept, add to your nix-darwin configuration:

```nix
environment.etc."ssh/ssh_config.d/nix-builders.conf".text = ''
  Host rpi
    HostName 192.168.1.x
    User <your-user>
    IdentityFile /etc/nix/builder_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
'';
```

Or edit `/etc/ssh/ssh_config` manually.

## 3. Authorize the key on the builder

Copy the public key to each builder machine:

```bash
sudo ssh-copy-id -i /etc/nix/builder_ed25519.pub <your-user>@rpi
```

The builder's Nix daemon must trust the connecting user. On the builder,
add to `nix.settings` (NixOS) or `/etc/nix/nix.conf`:

```nix
trusted-users = [ "root" "<your-user>" ];
```

## 4. Verify

```bash
# test SSH as root (how the daemon will connect)
sudo ssh -i /etc/nix/builder_ed25519 <your-user>@rpi echo ok

# test a build
just airsensor::build
```

If `sudo ssh` works but the build fails, check that the builder has
`trusted-users` configured correctly.

## Cloud builders

Cloud builders (Hetzner) handle SSH differently. Since instances are
ephemeral with dynamic IPs and rotating host keys, the builder string
embeds the host key directly (field 8, base64-encoded). The daemon uses
this embedded key for verification, bypassing `known_hosts` entirely.

`just builder::env` generates the full builder string including the
embedded host key via `ssh-keyscan`. No system-wide SSH config is needed
for cloud builders -- everything is in the `NIX_BUILDERS` variable.

```bash
just builder::up              # provision instances
eval $(just builder::env)     # export NIX_BUILDERS with embedded host keys
just airsensor::build         # builds using cloud builders
just builder::down            # tear down instances
```

See [infra/builder/README.md](../infra/builder/README.md) for cloud
builder configuration and scaling.
