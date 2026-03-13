{
  description = "SDS011 particulate matter Prometheus exporter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildGoModule {
            pname = "airdata";
            version = "0.1.0";
            src = ./.;
            vendorHash = "sha256-VlvXm3BigopGsFPl+Et3nWeMhWG3h+883bbdMeWe2Oo=";
            subPackages = [ "." ];
            postInstall = ''
              mv $out/bin/particulate $out/bin/airdata
            '';
          };
        }
      );

      nixosModules.default = import ./module.nix self;
    };
}
