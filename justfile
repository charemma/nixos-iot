_default:
    @just --list

# -- images --

# build gateway sd card image
build-gateway:
    nix build -o results/gateway --builders "$(just _builders)" .#nixosConfigurations.gateway.config.system.build.sdImage

# build airsensor sd card image
build-airsensor:
    nix build -o results/airsensor --builders "$(just _builders)" .#nixosConfigurations.airsensor.config.system.build.sdImage

# flash sd card image (usage: just flash gateway /dev/sdX)
flash host device:
    zstdcat results/{{host}}/sd-image/*.img.zst | sudo dd of={{device}} bs=4M status=progress conv=fsync

# -- builders --

# add a remote builder (usage: echo 'ssh://nix@host aarch64-linux' | just add-builder)
add-builder:
    cat >> builders.conf

# spin up cloud builders (Hetzner)
builder-up:
    just -f infra/builder/justfile up

# tear down cloud builders
builder-down:
    just -f infra/builder/justfile down

# show cloud builder status
builder-status:
    just -f infra/builder/justfile status

# internal: default builder (rpi5) + any extras from builders.conf
_builders:
    @{ echo 'ssh://rpi5 aarch64-linux'; cat builders.conf 2>/dev/null; } | paste -sd ';'
