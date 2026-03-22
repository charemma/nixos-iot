{
  description = "Gateway -- network appliance";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    platform.url = "path:../../modules";
    platform.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, platform, ... }: {
    nixosConfigurations.gateway = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        platform.nixosModules.raspberry-pi
        platform.nixosModules.sd-image
        platform.nixosModules.bsp-rpi
        platform.nixosModules.base
        platform.nixosModules.core
        platform.nixosModules.user
        platform.nixosModules.authorized-keys
        ./configuration.nix
      ];
    };
  };
}
