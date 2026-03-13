# Setting up a Raspberry Pi as a remote builder

This guide turns a Raspberry Pi into a remote ARM builder for Nix.
After setup, `just airsensor::build` on your dev machine compiles on
the Pi transparently.

## On the Pi

SSH into the Pi and make sure Nix is installed with flakes enabled. If
the Pi runs NixOS, add the following to its system configuration:

```nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  trusted-users = [ "root" "<your-user>" ];
};
```

`trusted-users` must include the user that the Nix daemon connects as
via SSH (the `user` from your SSH config in step 3 below). Without this,
the daemon will reject build requests with "user is not trusted".

Rebuild (`sudo nixos-rebuild switch`) and the Pi is ready.

On a non-NixOS Pi with Nix installed, add the same settings to
`/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
trusted-users = root <your-user>
```

Then restart the daemon: `sudo systemctl restart nix-daemon`.

## On the dev machine

### 1. Generate a dedicated build key (one-time)

```bash
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_ed25519 -N "" -C "nix-builder"
```

### 2. Authorize the key on the Pi

```bash
sudo ssh-copy-id -i /etc/nix/builder_ed25519.pub <your-user>@rpi
```

### 3. System-wide SSH config

The Nix daemon runs as root, so it uses root's SSH config -- not yours.
A per-user `~/.ssh/config` is not enough. Configure SSH system-wide so
that any user (including the daemon) can reach the builder.

On a NixOS dev machine, add to your system configuration:

```nix
programs.ssh.matchBlocks.rpi = {
  hostname = "192.168.1.x";
  user = "<your-user>";
  identityFile = "/etc/nix/builder_ed25519";
};
```

Optionally, skip host key verification. Useful when the Pi gets reflashed
and its host key changes:

```nix
programs.ssh.matchBlocks.rpi = {
  hostname = "192.168.1.x";
  user = "<your-user>";
  identityFile = "/etc/nix/builder_ed25519";
  extraOptions = {
    StrictHostKeyChecking = "no";
    UserKnownHostsFile = "/dev/null";
  };
};
```

Rebuild (`sudo nixos-rebuild switch`) and you're done.

## Verify

```bash
just airsensor::build
```

The justfile uses `ssh://rpi` as the default builder. If the connection
works, nix delegates the aarch64 compilation to the Pi and streams the
result back.

## Cloud builders (Hetzner)

Instead of a physical Pi, you can spin up ephemeral ARM instances on
Hetzner Cloud. The Pulumi project in `infra/builder/` handles provisioning
and automatically injects `/etc/nix/builder_ed25519.pub` so the instances
are immediately usable as builders.

One-time setup:

```bash
cd infra/builder
pulumi stack init dev
pulumi config set hcloud:token --secret
```

Then spin up, build, and tear down:

```bash
just builder::up
just builder::status | jq -r '.[] | "ssh://\(.user)@\(.host) \(.arch)"' | just builder::add
just airsensor::build
just builder::down
```

A `cax11` instance (2 vCPU ARM, 4 GB RAM) costs about 0.006 EUR/h.
Builders are ephemeral -- spin up before a build session, tear down after.

If your builder key lives at a different path:

```bash
pulumi config set sshPublicKeyPath /path/to/key.pub
```
