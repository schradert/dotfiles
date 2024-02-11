{inputs, ...}: {
  imports = [inputs.nixos-flake.flakeModule];
  perSystem = {
    config,
    nix,
    pkgs,
    self',
    ...
  }: {
    packages.default = self'.packages.activate;
    devShells.default = pkgs.mkShell {
      inputsFrom = nix.attrValues (nix.removeAttrs config.devShells ["default"]);
    };
  };
}
