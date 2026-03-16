_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# publish all build closures to binary cache
publish-cache:
    #!/usr/bin/env bash
    for dir in results/*/; do
        product=$(basename "$dir")
        echo "Publishing $product..."
        nix path-info -r "results/$product" | grep -v 'sd-image' | xargs attic push main
    done

# publish a single product closure to binary cache
_publish-cache-product product:
    nix path-info -r results/{{product}} | grep -v 'sd-image' | xargs attic push main

# internal: use NIX_BUILDERS if set, otherwise fall back to local rpi
_builders:
    @echo "${NIX_BUILDERS:-ssh://rpi aarch64-linux /etc/nix/builder_ed25519 4 1 - - -}"
