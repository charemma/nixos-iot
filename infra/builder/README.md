# Cloud Builder

On-demand ARM (aarch64) Nix remote builders on Hetzner Cloud, managed with Pulumi (TypeScript).

## Setup

```bash
# install dependencies
npm install

# initialize pulumi stack
pulumi stack init dev

# set hetzner API token (stored encrypted in stack state)
pulumi config set hcloud:token --secret
```

## Usage

From the repo root:

```bash
just builder-up       # spin up builders
just builder-down     # tear down builders
just builder-status   # show running builders as JSON
```

Or directly from this directory:

```bash
pulumi up --yes
pulumi destroy --yes
pulumi stack output output | jq .
```

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
