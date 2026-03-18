{
  description = "Sentinel Node -- edge security monitor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    platform.url = "path:../../modules";
    platform.inputs.nixpkgs.follows = "nixpkgs";
    sentinel.url = "path:../../apps/sentinel";
    sentinel.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, platform, sentinel, ... }: {
    nixosConfigurations.sentinel-node = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        platform.nixosModules.raspberry-pi
        platform.nixosModules.sd-image
        platform.nixosModules.bsp-rpi
        platform.nixosModules.base
        platform.nixosModules.user
        platform.nixosModules.authorized-keys
        sentinel.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
