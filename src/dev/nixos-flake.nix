{
  inputs,
  nix,
  ...
}: {
  imports = [inputs.nixos-flake.flakeModule];
  perSystem = {self', ...}: {
    nixos-flake.primary-inputs = nix.subtractLists ["self"] (nix.attrNames inputs);
    packages.default = self'.packages.activate;
    # TODO why isn't this package recognized?
    # packages.home = self'.packages.activate-home;
  };
}
