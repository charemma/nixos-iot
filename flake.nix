{
  description = "NixOS-based IoT/embedded platform for Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    airsensor.url = "path:./products/airsensor";
    airsensor.inputs.nixpkgs.follows = "nixpkgs";
    gateway.url = "path:./products/gateway";
    gateway.inputs.nixpkgs.follows = "nixpkgs";
    sentinel-node.url = "path:./products/sentinel-node";
    sentinel-node.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, airsensor, gateway, sentinel-node, ... }: {
    nixosConfigurations =
      airsensor.nixosConfigurations //
      gateway.nixosConfigurations //
      sentinel-node.nixosConfigurations;

    devShells = let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pulumi
            pulumiPackages.pulumi-nodejs
            nodejs
            jq
            just
          ];
        };
      }
    );
  };
}
