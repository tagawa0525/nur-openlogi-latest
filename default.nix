# nur-openlogi-latest
# NUR providing the latest OpenLogi release with daily auto-updates
{
  pkgs ? import <nixpkgs> { },
}:

{
  openlogi = pkgs.callPackage ./pkgs/openlogi { };
}
