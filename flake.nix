{
  description = "NUR providing the latest OpenLogi release with daily auto-updates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        import ./default.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        }
      );
    };
}
