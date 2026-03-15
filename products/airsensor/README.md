# airsensor

Air quality monitoring node built on a Raspberry Pi 5. Reads particulate matter
concentrations (PM2.5, PM10) from a Nova SDS011 sensor and exposes them as
Prometheus metrics.

## Hardware

- Raspberry Pi 5 (BCM2712, `aarch64-linux`)
- Nova SDS011 particulate matter sensor connected via USB (`/dev/ttyUSB0`)
- SD card boot

## Services

| Service | Description | Port |
|---------|-------------|------|
| airdata | SDS011 Prometheus exporter | 8000 |
| sshd | Remote access (key-only) | 22 |
| NetworkManager | Network configuration | -- |

The airdata service wakes the sensor every 5 minutes, takes a reading after a
30-second warm-up, and puts it back to sleep. This duty cycle extends the
sensor's rated lifespan (~8000 hours continuous).

Metrics endpoint: `http://airsensor:8000/metrics`

## Configuration

The product config (`configuration.nix`) composes:

- `raspberry-pi-nix` hardware module (board: `bcm2712`)
- `airdata` application module from `apps/airdata/`
- `authorized-keys` shared module for SSH access

## Usage

```bash
just airsensor::build          # build SD card image
just airsensor::flash /dev/sdX # flash to SD card
just airsensor::deploy         # deploy config update over SSH
```
