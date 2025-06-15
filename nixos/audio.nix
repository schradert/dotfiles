{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.client.audio.enable = lib.mkEnableOption "Audio processing";
    config = lib.mkIf config.dotfiles.client.audio.enable {
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
      users.users.tristan.extraGroups = ["audio"];
    };
  };
}
