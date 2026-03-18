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



## Threat Considerations

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



## Usage

```bash
just sentinel-node::build           # build SD card image
just sentinel-node::flash /dev/sdX  # flash to SD card
just sentinel-node::deploy          # update running device over SSH
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
