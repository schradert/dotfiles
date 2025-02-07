{inputs, ...}: {
  flake.overlays.nix-inspect = _: prev: {nix-inspect = inputs.nix-inspect.packages.${prev.system}.default;};
  canivete.deploy.system.homeModules.nix-inspect = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) nix-inspect;
    inherit (lib) mkEnableOption mkPackageOption mkIf;
  in {
    options.dotfiles.programs.nix-inspect = {
      enable = mkEnableOption "nix-inspect REPL TUI";
      package = mkPackageOption pkgs "nix-inspect" {};
    };
    config = mkIf nix-inspect.enable {
      home.packages = [nix-inspect.package];
    };
  };
}
