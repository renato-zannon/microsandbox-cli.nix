{
  description = "Nix packaging for microsandbox (msb)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          msb = pkgs.callPackage ./pkgs/msb { };
        in
        {
          inherit msb;
          default = msb;
        });

      overlays.default = final: _prev: {
        msb = final.callPackage ./pkgs/msb { };
      };
    };
}
