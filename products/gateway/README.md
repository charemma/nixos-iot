# gateway

Network gateway node built on a Raspberry Pi 5. Provides a WireGuard VPN
endpoint for secure remote access to the IoT network.

## Hardware

- Raspberry Pi 5 (BCM2712, `aarch64-linux`)
- SD card boot
- Ethernet and/or WiFi via NetworkManager

## Services

| Service | Description | Port |
|---------|-------------|------|
| WireGuard | VPN tunnel for remote device access | configurable |
| sshd | Remote access (key-only) | 22 |
| NetworkManager | Network configuration | -- |

## Configuration

The product config (`configuration.nix`) composes:

- `raspberry-pi-nix` hardware module (board: `bcm2712`)
- WireGuard via `networking.wireguard`
- `authorized-keys` shared module for SSH access

## Usage

```bash
just gateway::build          # build SD card image
just gateway::flash /dev/sdX # flash to SD card
just gateway::deploy         # deploy config update over SSH
```
