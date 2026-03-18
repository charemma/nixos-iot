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
      modules = builtins.attrValues platform.nixosModules ++ [
        airdata.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
