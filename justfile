_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# internal: use NIX_BUILDERS if set, otherwise fall back to local rpi
_builders:
    @echo "${NIX_BUILDERS:-ssh://rpi aarch64-linux}"
