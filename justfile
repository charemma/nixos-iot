_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# internal: default builder (rpi) + any extras from cloud builders
_builders:
    @{ echo 'ssh://rpi aarch64-linux'; cat infra/builder/builders.conf 2>/dev/null; } | paste -sd ';'
