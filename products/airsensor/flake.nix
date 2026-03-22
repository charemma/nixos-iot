{
  description = "Airsensor -- particulate matter monitoring station";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    platform.url = "path:../../modules";
    platform.inputs.nixpkgs.follows = "nixpkgs";
    airdata.url = "path:../../apps/airdata";
    airdata.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, platform, airdata, ... }: {
    nixosConfigurations.airsensor = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        platform.nixosModules.raspberry-pi
        platform.nixosModules.sd-image
        platform.nixosModules.bsp-rpi
        platform.nixosModules.base
        platform.nixosModules.core
        platform.nixosModules.user
        platform.nixosModules.authorized-keys
        airdata.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
