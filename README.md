# microsandbox-cli.nix

Nix flake for the [microsandbox](https://microsandbox.dev/) CLI.

**NOTE**: This repository is not affiliated with or endorsed by the upstream project. It is just a small helper I made for myself, and that could be useful to others that also prefer managing developer tooling using nix.
Refer to the [upstream project](https://github.com/superradcompany/microsandbox) for the actual tool and its documentation.

## Flake Outputs

- `msb`: built from source with `crane` on `x86_64-linux`
- `msb-prebuilt`: upstream prebuilt binary package
- `default`: aliases `msb`

## Quick Start

Build the source package:

```bash
nix build .#msb
```

Run it directly:

```bash
nix run .#msb -- run ubuntu
```

Use the prebuilt package instead:

```bash
nix build .#msb-prebuilt
```

## Install

Install with `nix profile`:

```bash
nix profile install github:renato-zannon/microsandbox-cli.nix#msb
```

Install with Home Manager:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    microsandbox-nix.url = "github:renato-zannon/microsandbox-cli.nix";
  };

  outputs = { self, nixpkgs, home-manager, microsandbox-nix, ... }:
    {
      homeConfigurations."your-user" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          {
            home.packages = [ microsandbox-nix.packages.x86_64-linux.msb ];
          }
        ];
      };
    };
}
```

## Notes

- The source build is currently supported on `x86_64-linux` only.
- The prebuilt package is available for `x86_64-linux` and `aarch64-linux`.
- `msb` also installs a `microsandbox` binary alias.

## Use As An Overlay

```nix
inputs.microsandbox-nix.url = "github:renato-zannon/microsandbox-cli.nix";

outputs = { self, nixpkgs, microsandbox-nix, ... }:
  {
    overlays.default = microsandbox-nix.overlays.default;
  };
```
