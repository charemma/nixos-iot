# Setting up a Raspberry Pi as a remote builder

This guide turns a Raspberry Pi into a remote ARM builder for Nix.
After setup, `just airsensor::build` on your dev machine compiles on
the Pi transparently.

Before following this guide, make sure your dev machine is configured
for remote builds. See [dev machine setup](dev-machine-setup.md).

## On the Pi

SSH into the Pi and make sure Nix is installed with flakes enabled. If
the Pi runs NixOS, add the following to its system configuration:

```nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  trusted-users = [ "root" "<your-user>" ];
};
```

`trusted-users` must include the SSH user that the Nix daemon connects
as. The daemon runs as root on your dev machine and opens the SSH
connection as root, but authenticates as the user from your SSH config
(e.g. `charemma` in `Host rpi`). That user must be trusted on the builder
side.

Without this, the builder's daemon will reject build requests with
"user is not trusted".

Rebuild (`sudo nixos-rebuild switch`) and the Pi is ready.

On a non-NixOS Pi with Nix installed, add the same settings to
`/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
trusted-users = root <your-user>
```

Then restart the daemon: `sudo systemctl restart nix-daemon`.

## Authorize the build key

Copy the builder public key to the Pi:

```bash
sudo ssh-copy-id -i /etc/nix/builder_ed25519.pub <your-user>@rpi
```

## Verify

```bash
# test that root can reach the Pi (this is how the daemon connects)
sudo ssh -i /etc/nix/builder_ed25519 <your-user>@rpi echo ok

# run a build
just airsensor::build
```

The justfile uses `ssh://rpi` as the default builder. If the connection
works, Nix delegates the aarch64 compilation to the Pi and streams the
result back.

## Cloud builders

For cloud builders (Hetzner), see [infra/builder/README.md](../infra/builder/README.md).
Cloud builders handle SSH automatically -- the builder string includes
embedded host keys, and `just builder::up` provisions instances with
the correct public key.
