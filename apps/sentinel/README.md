# sentinel

Lightweight network security monitor for edge devices. Passively observes
network traffic and exposes basic security indicators as Prometheus metrics.

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

## Sentinel Service (Rust)

The sentinel service is a lightweight network observer.

Responsibilities:

- passive packet capture (libpcap)
- extraction of:
  - connection metadata
  - DNS requests
  - unusual port usage
- basic anomaly indicators (e.g. connection bursts)

The focus is robustness and simplicity, not deep packet inspection.

Rust is used for:

- memory safety
- predictable runtime behavior
- suitability for long-running system services

## Threat Considerations

This project explores mitigation of common risks in embedded systems:

| Threat | Mitigation |
|--------|------------|
| System drift / inconsistent state | Declarative NixOS configuration |
| Supply chain manipulation | Reproducible builds |
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

## Development

Build and test locally:

```bash
cd apps/sentinel
cargo build
./target/debug/sentinel
curl localhost:9090/metrics
```

Or via Nix:

```bash
nix build ./apps/sentinel
./result/bin/sentinel
```

Deploy to a running device:

```bash
just sentinel-node::deploy
```

## NixOS integration

Enable in a product configuration:

```nix
services.sentinel = {
  enable = true;
  interface = "eth0";
  port = 9090;
};
```

The module creates a hardened systemd service with minimal privileges
(DynamicUser, CAP_NET_RAW only, strict filesystem protection).

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
