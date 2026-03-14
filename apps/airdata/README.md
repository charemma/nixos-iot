# airdata

Prometheus exporter for the SDS011 particulate matter sensor. Reads PM2.5 and PM10 concentrations via serial (`/dev/ttyUSB0`) and exposes them as Prometheus metrics on `:8000/metrics`.

## How it works

The daemon wakes the SDS011 sensor every 5 minutes, waits 30 seconds for it to warm up, takes a reading, and puts it back to sleep. This extends the sensor's lifespan (rated for ~8000 hours of continuous use).

Metrics exposed:

| Metric | Description |
|--------|-------------|
| `pm25` | PM2.5 concentration in ug/m3 |
| `pm10` | PM10 concentration in ug/m3 |

## Development

Build and test locally without touching a device:

```bash
cd apps/airdata
go build && ./airdata -port 9090
go test ./...
```

Or via Nix:

```bash
nix build ./apps/airdata
./result/bin/airdata -h
```

Deploy to a running device over SSH (no reflash needed):

```bash
just airsensor::deploy
```

A full SD image (`just airsensor::build` + `just airsensor::flash`) is
only needed for initial provisioning or boot-level changes.

## NixOS integration

This app provides a NixOS module via `flake.nix`. Enable it in a host config:

```nix
services.airdata = {
  enable = true;
  device = "/dev/ttyUSB0";  # default
  port = 8000;               # default
};
```

The module creates a hardened systemd service with minimal privileges (DynamicUser, restricted filesystem access, only `dialout` group for serial access).

## Hardware

- **Sensor**: Nova SDS011 (USB-to-serial, 9600 baud)
- **Target**: Raspberry Pi 5 running NixOS
- **Connection**: USB-A cable, shows up as `/dev/ttyUSB0`
