# nur-openlogi-latest

A NUR (Nix User Repository) that provides the latest release of [OpenLogi](https://github.com/AprilNEA/OpenLogi), automatically updated daily via GitHub Actions.

## Packages

| Package    | Description                                                                  |
| ---------- | ---------------------------------------------------------------------------- |
| `openlogi` | OpenLogi (CLI, agent, desktop GUI, overlay) - latest release, `x86_64-linux` |

## Why This Repository?

OpenLogi is written in Rust and its GPUI-based GUI takes a long time to compile, while upstream releases every few days. There is no public Nix binary cache for it. This repository:

- Repackages the prebuilt Linux release (`.pkg.tar.zst`) with `autoPatchelfHook`, so nothing is compiled
- Verifies each release package with upstream's minisign key before recording its hash
- Adds the libraries GPUI loads at runtime (libGL, Vulkan, Wayland) to every binary, including `openlogi-overlay`
- Builds the package (including a `--version` check) before committing an update

## Usage

### With Flakes

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur-openlogi-latest = {
      url = "github:tagawa0525/nur-openlogi-latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nur-openlogi-latest, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nur-openlogi-latest.packages.${pkgs.stdenv.hostPlatform.system}.openlogi
          ];
        })
      ];
    };
  };
}
```

The package ships the upstream udev rule (`lib/udev/rules.d`) and systemd user unit (`share/systemd/user`); add it to `services.udev.packages` / `systemd.packages` if you want to use them as-is.

### Without Flakes

```bash
nix-build -A openlogi
```

## How It Works

`.github/workflows/update-openlogi.yml` runs daily:

1. Reads the latest release tag of `AprilNEA/OpenLogi`
2. Downloads the `linux-amd64.pkg.tar.zst` asset and its `.minisig`, and verifies the signature against the pinned public key
3. Writes the version and SRI hash to `pkgs/openlogi/sources.json`
4. Builds the package and commits the change

## License

The Nix expressions in this repository are MIT licensed. OpenLogi itself is licensed under MIT OR Apache-2.0.
