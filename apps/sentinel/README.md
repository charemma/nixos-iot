# sentinel

Lightweight network security monitor. Passively captures traffic via
libpcap and exposes security indicators as Prometheus metrics and
structured JSON event logs.

## What it does

- passive packet capture on a given network interface (promiscuous mode)
- tracks total packets, bytes, unique source IPs
- detects TCP connection attempts (SYN packets)
- extracts DNS queries with domain names
- exposes Prometheus metrics on `/metrics`
- emits structured JSON events to stderr (picked up by journald)

## Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `sentinel_up` | gauge | Service is running |
| `sentinel_packets_total` | counter | Total packets captured |
| `sentinel_bytes_total` | counter | Total bytes captured |
| `sentinel_dns_queries_total` | counter | DNS queries observed |
| `sentinel_tcp_syn_total` | counter | TCP connection attempts |
| `sentinel_unique_sources` | gauge | Unique source IPs seen |

## Event Log

Events are emitted as JSON lines to stderr:

```json
{"type":"dns_query","src":"192.168.1.10","domain":"example.com"}
{"type":"tcp_connect","src":"192.168.1.10","dst":"192.168.1.1","dport":443}
```

On NixOS, journald captures these automatically:

```bash
journalctl -u sentinel -f -o cat
```

## Development

```bash
cd apps/sentinel
direnv allow
cargo build
sudo ./target/debug/sentinel    # needs CAP_NET_RAW
```

## NixOS module

| Option | Default | Description |
|--------|---------|-------------|
| `services.sentinel.enable` | `false` | Enable the service |
| `services.sentinel.interface` | `"eth0"` | Network interface to monitor |
| `services.sentinel.port` | `9090` | Prometheus metrics port |
