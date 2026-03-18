{
  description = "Sentinel Node -- edge security monitor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # shared platform modules (BSP, base system, user management)
    platform.url = "path:../../modules";
    platform.inputs.nixpkgs.follows = "nixpkgs";

    # sentinel network monitor application
    sentinel.url = "path:../../apps/sentinel";
    sentinel.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, platform, sentinel, ... }: {
    nixosConfigurations.sentinel-node = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # hardware support
        platform.nixosModules.raspberry-pi
        platform.nixosModules.sd-image
        platform.nixosModules.bsp-rpi

        # base system (networking, locale, SSH, flakes)
        platform.nixosModules.base
        platform.nixosModules.user
        platform.nixosModules.authorized-keys

        # note: core.nix deliberately excluded -- no debug tools on a
        # hardened security node (no vim, htop, curl, tmux)

        # application
        sentinel.nixosModules.default

        # product-specific config (hardening, firewall, audit)
        ./configuration.nix
      ];
    };
  };
}
