# Development workflow

Day-to-day development does not require flashing SD cards. Build the
app locally, iterate, and push changes to a running device over SSH.

## Enter the dev shell

```bash
direnv allow    # or: nix develop
```

## Build and test an app locally

Apps live in `apps/` and are standalone Nix flakes. Build and run them
on your dev machine without touching a device:

```bash
nix build ./apps/airdata
./result/bin/airdata -h
```

For faster iteration, use the language toolchain directly:

```bash
cd apps/airdata
go build && ./airdata -port 9090
go test ./...
```

## Deploy to a running device

Once satisfied, deploy the full system config (including the updated app)
to a running device over SSH:

```bash
just airsensor::deploy
```

This runs `nixos-rebuild switch` on the target device. The device
pulls the new configuration, rebuilds, and switches -- no reflash needed.

## When to build an SD image

A full image build (`just airsensor::build` + `just airsensor::flash`)
is only needed for:

- Initial provisioning of a new device
- Changes to the boot process, kernel, or partition layout
- Recovery after a broken deploy
