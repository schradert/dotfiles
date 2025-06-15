{
  dotfiles.nixos = {config, lib, pkgs, ...}: {
    options.dotfiles.client.enable = lib.mkEnableOption "client";
    config = lib.mkIf config.dotfiles.client.enable {
      dotfiles.client = {
        plasma.enable = true;
        fhs.enable = true;
        audio.enable = true;
        video.enable = true;
      };
      dotfiles.nixpkgs.config.allowUnfreePackages = ["beeper"];
      home-manager.sharedModules = [
        ({pkgs, ...}: {
          home.packages = with pkgs; [brave beeper legcord k3d bitwarden];
          programs.rbw.enable = true;
        })
      ];
    };
  };
}
