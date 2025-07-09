{
  dotfiles.nixos = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.profiles.client.fhs.enable = lib.mkEnableOption "FHS compatibility system-wide";
    config = lib.mkIf config.dotfiles.profiles.client.fhs.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "FHS is for clients";
      };
      environment.systemPackages = [pkgs.nix-alien];
      nixpkgs.overlays = [flake.inputs.nix-alien.overlays.default];
      programs.nix-ld.enable = true;
      services.envfs.enable = true;
    };
  };
}
