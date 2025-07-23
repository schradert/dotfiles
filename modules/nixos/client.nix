{
  dotfiles.nixos = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkMerge;
  in {
    options.dotfiles.profiles.client.enable = mkEnableOption "client";
    config = mkIf config.dotfiles.profiles.client.enable {
      dotfiles.profiles.client = {
        plasma.enable = mkDefault true;
        fhs.enable = mkDefault true;
        audio.enable = mkDefault true;
        video.enable = mkDefault true;
      };
      dotfiles.nixpkgs.config.allowUnfreePackages = ["beeper"];
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          home.packages = with pkgs;
            mkMerge [
              [brave legcord k3d bitwarden]
              (mkIf (stdenv.hostPlatform.system == "x86_64-linux") [beeper])
            ];
          programs.rbw.enable = true;
        })
      ];
      users.mutableUsers = true;
    };
  };
}
