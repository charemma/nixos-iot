#!/usr/bin/env bash
# SSH wrapper for nix remote builders. Skips host key verification
# for ephemeral cloud builders with dynamic IPs and rotating keys.
exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /etc/nix/builder_ed25519 "$@"
