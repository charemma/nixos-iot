# Cloud Builder

On-demand ARM (aarch64) Nix remote builders on Hetzner Cloud, managed with Pulumi (TypeScript).

## Prerequisites

- A [Pulumi account](https://app.pulumi.com/) (free tier works)
- A [Hetzner Cloud](https://www.hetzner.com/cloud/) account with API access
- A dedicated Nix builder SSH key at `/etc/nix/builder_ed25519` (see [dev machine setup](../../docs/dev-machine-setup.md))

## Setup

```bash
# log in to Pulumi (one-time, creates/links your account)
pulumi login

# initialize the stack
cd infra/builder
pulumi stack init dev

# set Hetzner API token (stored encrypted in Pulumi state)
pulumi config set hcloud:token --secret
```

The Pulumi state is stored in Pulumi Cloud by default. If you prefer a local or self-hosted backend, see the [Pulumi backends docs](https://www.pulumi.com/docs/iac/concepts/state-and-backends/).

## Usage

From the repo root:

```bash
just builder::up              # provision builders
eval $(just builder::env)     # export NIX_BUILDERS
just airsensor::build         # build using the cloud builders
just builder::down            # tear down builders
```

`builder::env` generates the `NIX_BUILDERS` variable with the full
builder string for each instance, including base64-encoded host keys
(fetched via `ssh-keyscan`). The Nix daemon uses these embedded keys
for host verification, so no SSH config or `known_hosts` entries are
needed for cloud builders.

After `builder::up`, wait about 90 seconds for cloud-init to finish
installing Nix on the instances before starting a build.

## Configuration

Edit `Pulumi.dev.yaml` to change server types or scale:

```yaml
config:
  nix-builder:builders:
    aarch64:
      serverType: cax11    # 2 vCPU, 4 GB RAM -- 0.006 EUR/h
      cores: 2
      count: 1             # increase for parallel builds
```

Available ARM types: `cax11` (2 cores), `cax21` (4), `cax31` (8), `cax41` (16).

The SSH public key defaults to `/etc/nix/builder_ed25519.pub`. Override with:

```bash
pulumi config set sshPublicKeyPath /path/to/key.pub
```
