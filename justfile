_default:
    @just --list --list-submodules

mod airsensor 'products/airsensor/justfile'
mod gateway 'products/gateway/justfile'
mod builder 'infra/builder/justfile'

# publish build closures to binary cache (usage: just publish-cache [product])
publish-cache product="":
    #!/usr/bin/env bash
    if [ -n "{{product}}" ]; then
        nix path-info -r "results/{{product}}" | grep -v 'sd-image' | xargs attic push main
    else
        for dir in results/*/; do
            product=$(basename "$dir")
            echo "Publishing $product..."
            nix path-info -r "results/$product" | grep -v 'sd-image' | xargs attic push main
        done
    fi

# internal: use NIX_BUILDERS if set, otherwise fall back to local rpi
_builders:
    @echo "${NIX_BUILDERS:-ssh://rpi aarch64-linux /etc/nix/builder_ed25519 4 1 - - -}"
