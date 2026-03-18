# sentinel

Lightweight network security monitor. Passively captures traffic via
libpcap and exposes basic security indicators as Prometheus metrics.

## What it does

- passive packet capture on a given network interface
- extraction of connection metadata, DNS requests, unusual port usage
- basic anomaly indicators (e.g. connection bursts)
- Prometheus metrics endpoint for scraping

The focus is robustness and simplicity, not deep packet inspection.

## Development

```bash
cd apps/sentinel
cargo build
./target/debug/sentinel
curl localhost:9090/metrics
```

## NixOS module

The app exposes a NixOS module via `flake.nix`. Options:

| Option | Default | Description |
|--------|---------|-------------|
| `services.sentinel.enable` | `false` | Enable the service |
| `services.sentinel.interface` | `"eth0"` | Network interface to monitor |
| `services.sentinel.port` | `9090` | Prometheus metrics port |
