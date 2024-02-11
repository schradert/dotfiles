{inputs, ...}: {
  flake.homeModules.sops-nix = inputs.sops-nix.homeManagerModules.sops;
  perSystem = {
    config,
    nix,
    pkgs,
    ...
  }: {
    # # Upgrading sops because: https://github.com/getsops/sops/issues/1263
    # # Overriding go modules requires overriding the buildGoModule function instead of attributes directly.
    # # Follow the discussion and activity below:
    # # [Issue](https://github.com/NixOS/nixpkgs/issues/86349)
    # # [PR: buildGoModule](https://github.com/NixOS/nixpkgs/pull/225051)
    # # [PR: lib.extendMkDerivation](https://github.com/NixOS/nixpkgs/pull/234651)
    packages.sops = pkgs.sops.override {
      buildGoModule = args:
        pkgs.buildGoModule (args
          // rec {
            version = "3.8.1";
            src = pkgs.fetchFromGitHub {
              owner = "mozilla";
              repo = args.pname;
              rev = "v${version}";
              sha256 = "4K09wLV1+TvYTtvha6YyGhjlhEldWL1eVazNwcEhi3Q=";
            };
            vendorHash = "sha256-iRgLspYhwSVuL0yarPdjXCKfjK7TGDZeQCOcIYtNvzA=";
          });
    };
    devShells.sops = pkgs.mkShell {
      packages = [config.packages.sops];
    };
  };
}
