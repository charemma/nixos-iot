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
      modules = builtins.attrValues platform.nixosModules ++ [
        sentinel.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
