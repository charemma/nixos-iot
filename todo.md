# TODO

## README improvements

### Production disclaimer

Add a section to the README clarifying this is a reference implementation, not a production-ready setup. Mention at least:

- **Binary cache**: production setups should run a private binary cache (e.g. Attic, Cachix, or an S3-backed nix-serve). Reasons: supply chain security (don't blindly trust cache.nixos.org on production devices), build performance (avoid rebuilding on every device or CI run), and availability (no dependency on external infrastructure during deploys).
- **Secrets management**: use agenix or sops-nix instead of baking secrets into the config. The current authorized-keys module is fine for a demo but production needs encrypted secrets at rest.
- **Automatic updates**: production fleets need an update mechanism (e.g. nixos-rebuild triggered via fleet management, or A/B partition schemes for atomic rollback).
- **Image signing**: sign SD card images and verify on boot to prevent tampering.
- **Monitoring and alerting**: airdata exposes Prometheus metrics but there's no scraping, alerting, or dashboarding set up.
- **Firewall rules**: the product configs don't set any firewall rules. Production devices should have restrictive iptables/nftables defaults.

### Product descriptions

Flesh out `products/airsensor/README.md` and `products/gateway/README.md` with more substance (hardware, purpose, services, network topology).

## Shared modules

- Extract a `modules/core.nix` with common tools (htop, vim, curl, tmux or similar) shared across all products for demo/debugging purposes.
- Extract user setup (iot user, group, sudo config) from product configs into `modules/user.nix` to reduce duplication.
- Extract shared base config (timezone, locale, flakes, openssh, filesystem, board) into modules where it makes sense.

## CLAUDE.md

- Improvements already staged on main (separate commit needed).
