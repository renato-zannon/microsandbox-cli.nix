{
  description = "Nix packaging for microsandbox (msb)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, crane, rust-overlay }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };
          craneLib = (crane.mkLib pkgs).overrideToolchain (
            pkgs.rust-bin.stable.latest.default.override {
              targets = [ "x86_64-unknown-linux-musl" ];
            }
          );
          msb = pkgs.callPackage ./pkgs/msb {
            inherit craneLib;
          };
          msb-prebuilt = pkgs.callPackage ./pkgs/msb-prebuilt { };
        in
        {
          inherit msb msb-prebuilt;
          default = msb;
        });

      overlays.default = final: _prev: {
        msb = final.callPackage ./pkgs/msb {
          craneLib = (crane.mkLib final).overrideToolchain (
            final.rust-bin.stable.latest.default.override {
              targets = [ "x86_64-unknown-linux-musl" ];
            }
          );
        };
        msb-prebuilt = final.callPackage ./pkgs/msb-prebuilt { };
      };
    };
}
