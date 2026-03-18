{
  description = "Shared NixOS modules for the IoT platform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
  };

  outputs = { self, nixpkgs, raspberry-pi-nix, ... }: {
    nixosModules = {
      bsp-rpi = import ./bsp-rpi.nix;
      base = import ./base.nix;
      core = import ./core.nix;
      user = import ./user.nix;
      authorized-keys = import ./authorized-keys.nix;
      raspberry-pi = raspberry-pi-nix.nixosModules.raspberry-pi;
      sd-image = raspberry-pi-nix.nixosModules.sd-image;
    };
  };
}
