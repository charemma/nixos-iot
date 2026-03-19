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
      # modules shared across all targets (hardware, VM, UTM)
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

      vmModule = system: "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix";
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
            (vmModule "x86_64-linux")
            {
              # bridge networking: VM gets own IP, sees real traffic
              # fixed MAC so the VM is identifiable via arp-scan
              virtualisation.qemu.networkingOptions = [
                "-nic bridge,br=br0,model=virtio,mac=52:54:00:5e:4e:01"
              ];
            }
          ];
        };

        # dev VM: aarch64 for macOS (Apple Silicon) via UTM or QEMU
        sentinel-node-vm-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = commonModules ++ [
            (vmModule "aarch64-linux")
            {
              virtualisation.qemu.networkingOptions = [
                "-nic vmnet-shared,model=virtio,mac=52:54:00:5e:4e:01"
              ];
            }
          ];
        };
      };
    };
}
