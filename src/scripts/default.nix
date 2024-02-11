{
  perSystem = {
    nix,
    pkgs,
    ...
  }: {
    packages.nixos = pkgs.writeShellScriptBin "nixos" (nix.readFile ./nixos.sh);
  };
}
