_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# internal: combine default builder (rpi) with any cloud builders from NIX_BUILDERS
_builders:
    @{ echo 'ssh://rpi aarch64-linux'; echo "${NIX_BUILDERS:-}"; } | grep -v '^$' | paste -sd ';'
