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
      modules = builtins.attrValues platform.nixosModules ++ [
        ./configuration.nix
      ];
    };
  };
}
