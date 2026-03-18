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

  outputs = { self, nixpkgs, platform, sentinel, ... }:
    let
      # modules shared between VM and hardware targets
      commonModules = [
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
    in {
      nixosConfigurations = {
        # release target: aarch64 SD card image for Raspberry Pi
        sentinel-node = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            platform.nixosModules.raspberry-pi
            platform.nixosModules.sd-image
            platform.nixosModules.bsp-rpi
          ] ++ commonModules;
        };

        # dev target: x86_64 QEMU VM for local testing
        sentinel-node-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules;
        };
      };
    };
}
