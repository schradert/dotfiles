{
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.nixpkgs.config.allowUnfreePackages = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };
    config.nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) config.dotfiles.nixpkgs.config.allowUnfreePackages;
  };
}
