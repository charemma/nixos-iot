_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# internal: default builder (rpi) + any extras from builders.conf
_builders:
    @{ echo 'ssh://rpi aarch64-linux'; cat builders.conf 2>/dev/null; } | paste -sd ';'
