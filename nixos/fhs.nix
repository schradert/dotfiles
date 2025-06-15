{
  dotfiles.nixos = {config, flake, lib, pkgs, ...}: {
    options.dotfiles.client.fhs.enable = lib.mkEnableOption "FHS compatibility system-wide";
    config = lib.mkIf config.dotfiles.client.fhs.enable {
      environment.systemPackages = [pkgs.nix-alien];
      nixpkgs.overlays = [flake.inputs.nix-alien.overlays.default];
      programs.nix-ld.enable = true;
      services.envfs.enable = true;
    };
  };
}
