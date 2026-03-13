_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# internal: default builder (rpi5) + any extras from builders.conf
_builders:
    @{ echo 'ssh://rpi5 aarch64-linux'; cat builders.conf 2>/dev/null; } | paste -sd ';'
