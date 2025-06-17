{
  dotfiles = {config, ...}: let
    inherit (config) me;
  in {
    nixos = {config, lib, ...}: {
      options.dotfiles.profiles.client.audio.enable = lib.mkEnableOption "Audio processing";
      config = lib.mkIf config.dotfiles.profiles.client.audio.enable {
        assertions = lib.toList {
          assertion = config.dotfiles.profiles.client.enable;
          message = "Audio is for clients";
        };
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = with pkgs; [pavucontrol spotify];
          })
        ];
        dotfiles.nixpkgs.config.allowUnfreePackages = ["spotify"];
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
        users.users.${me}.extraGroups = ["audio"];
      };
    };
  };
}
