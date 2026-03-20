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
      # modules shared across all targets (hardware, VM)
      commonModules = [
        platform.nixosModules.base
        platform.nixosModules.user
        platform.nixosModules.authorized-keys

        # note: core.nix deliberately excluded -- no debug tools on a
        # hardened security node (no vim, htop, curl, tmux)

        sentinel.nixosModules.default
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

        # dev VM: x86_64 for Linux hosts
        sentinel-node-vm-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ [
            platform.nixosModules.vm-image
            { boot.kernelParams = [ "console=ttyS0,115200n8" ]; }
          ];
        };

        # dev VM: aarch64 for macOS (Apple Silicon)
        sentinel-node-vm-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = commonModules ++ [
            platform.nixosModules.vm-image
            { boot.kernelParams = [ "console=ttyAMA0,115200n8" ]; }
          ];
        };
      };
    };
}
