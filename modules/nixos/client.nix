{
  dotfiles.shared = {lib, ...}: {options.dotfiles.profiles.client.enable = lib.mkEnableOption "client";};
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      dotfiles.profiles.client = {
        plasma.enable = mkDefault true;
        fhs.enable = mkDefault true;
        audio.enable = mkDefault true;
        video.enable = mkDefault true;
      };
      dotfiles.nixpkgs.config.allowUnfreePackages = ["beeper"];
      users.mutableUsers = true;
      home-manager.sharedModules = [{dotfiles.profiles.client.enable = true;}];
    };
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      home.packages = with pkgs;
        lib.mkMerge [
          [brave legcord k3d bitwarden]
          (lib.mkIf (stdenv.hostPlatform.system == "x86_64-linux") [beeper])
        ];
      programs.rbw.enable = true;
    };
  };
}
