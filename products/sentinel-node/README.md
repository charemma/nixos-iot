# sentinel-node

Secure edge security node for passive network monitoring. Built on NixOS
for reproducibility, minimal attack surface, and hardened runtime.

## Architecture

```
+------------------------+
| Sentinel Node Device   |
+------------------------+
| NixOS Base System      |
| - minimal services     |
| - hardened config      |
+------------------------+
| Sentinel Service       |
| (Rust)                 |
| - packet capture       |
| - lightweight parsing  |
| - event generation     |
+------------------------+
```

## Build Targets

The product has two build targets sharing the same configuration:

| Target | Arch | Purpose |
|--------|------|---------|
| `sentinel-node` | aarch64 | SD card image for Raspberry Pi (release) |
| `sentinel-node-vm` | x86_64 | QEMU VM for local development and testing |

The VM target skips the RPi BSP and SD image modules. Everything else
(application, hardening, firewall, audit) is identical.

## Usage

### Local VM (development)

Build and boot the VM locally, no ARM builder or hardware needed:

```bash
just sentinel-node::vm
```

NixOS generates a QEMU runner script automatically from the system
configuration. The VM boots into a full NixOS system with all hardening
and services active.

Connect to the running VM via SSH port forwarding:

```bash
QEMU_NET_OPTS="hostfwd=tcp::2222-:22,hostfwd=tcp::9090-:9090" \
  just sentinel-node::vm
```

Then in another terminal:

```bash
ssh -p 2222 iot@localhost       # SSH into the VM
curl localhost:9090/metrics     # query sentinel metrics
```

Note: there is no interactive console login (hardening). SSH is the
only way to access the system.

### Hardware (release)

Build the SD card image for Raspberry Pi (requires ARM builder):

```bash
just sentinel-node::build           # build SD card image
just sentinel-node::flash /dev/sdX  # flash to SD card
just sentinel-node::deploy          # update running device over SSH
```

## Supply Chain Policy

Sentinel-node builds do not pull binary substitutes from cache.nixos.org.
All packages are either built from source or fetched from the internal
binary cache (`nix.charemma.de`) that contains only self-built artifacts.

This ensures full provenance over every component in the image.

After the first (from-source) build, push artifacts to the internal cache:

```bash
just sentinel-node::publish-cache
```

## Configuration

Product config in `configuration.nix`:

```nix
services.sentinel = {
  enable = true;
  interface = "eth0";
  port = 9090;
};
```

The sentinel service runs as a hardened systemd unit with minimal
privileges (DynamicUser, CAP_NET_RAW only, strict filesystem protection).

## System Hardening

The product configuration includes:

- **Firewall**: default-deny, only SSH (22) and metrics (9090) open
- **Kernel**: kptr_restrict, dmesg_restrict, no unprivileged BPF, hardened JIT
- **Network**: IP forwarding disabled (observe-only, no routing)
- **Modules**: bluetooth, firewire, thunderbolt blacklisted
- **Login**: no interactive console, SSH-only management
- **Audit**: auditd with execve logging for all process execution
- **Service**: no debug tools installed (core.nix excluded)

## Threat Considerations

| Threat | Mitigation |
|--------|------------|
| System drift / inconsistent state | Declarative NixOS configuration |
| Supply chain manipulation | Reproducible builds, internal cache only |
| Excessive attack surface | Minimal system design |
| Unsafe runtime environments | Sandboxed services |

Reproducible systems also improve auditability, since the full system
state can be reconstructed and verified.

## Why Edge-Based Security?

Deploying security functionality directly at the edge enables:

- visibility into local network traffic
- reduced dependency on central infrastructure
- lower latency for detection
- better control over sensitive data

## Scope

This project is intentionally limited in scope.

It is:

- a system design exploration
- a minimal security component
- a platform building block

It is NOT:

- a full IDS
- a SIEM system
- a penetration testing toolkit

## Future Directions

- integration with remote event collectors
- secure update mechanisms (signed deployments)
- eBPF-based filtering
- higher throughput packet processing (e.g. DPDK)
