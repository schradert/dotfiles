{
  dotfiles.nixos = {config, lib, pkgs, ...}: {
    options.dotfiles.profiles.client.enable = lib.mkEnableOption "client";
    config = lib.mkIf config.dotfiles.profiles.client.enable {
      dotfiles.profiles.client = {
        plasma.enable = lib.mkDefault true;
        fhs.enable = lib.mkDefault true;
        audio.enable = lib.mkDefault true;
        video.enable = lib.mkDefault true;
      };
      dotfiles.nixpkgs.config.allowUnfreePackages = ["beeper"];
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          home.packages = with pkgs; [brave beeper legcord k3d bitwarden];
          programs.rbw.enable = true;
        })
      ];
      users.mutableUsers = true;
    };
  };
}
