{
  description = "NixOS-based IoT/embedded image builder for Raspberry Pi 5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    airdata.url = "path:./apps/airdata";
    airdata.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, raspberry-pi-nix, airdata, ... }:
    let
      sharedModules = [
        raspberry-pi-nix.nixosModules.raspberry-pi
        raspberry-pi-nix.nixosModules.sd-image
        ./modules/rpi.nix
        ./modules/base.nix
        ./modules/core.nix
        ./modules/user.nix
        ./modules/authorized-keys.nix
      ];
    in {
    nixosConfigurations = {
      gateway = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = sharedModules ++ [
          ./products/gateway/configuration.nix
        ];
      };

      airsensor = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = sharedModules ++ [
          airdata.nixosModules.default
          ./products/airsensor/configuration.nix
        ];
      };
    };

    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = with nixpkgs.legacyPackages.x86_64-linux; [
        pulumi
        pulumiPackages.pulumi-nodejs
        nodejs
        jq
        just
      ];
    };
  };
}
