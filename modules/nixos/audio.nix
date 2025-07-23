{
  dotfiles = {config, ...}: let
    inherit (config) me;
  in {
    nixos = {
      config,
      lib,
      perSystem,
      ...
    }: let
      inherit (lib) mkEnableOption mkIf mkMerge toList;
    in {
      options.dotfiles.profiles.client.audio.enable = mkEnableOption "Audio processing";
      config = mkIf config.dotfiles.profiles.client.audio.enable {
        assertions = toList {
          assertion = config.dotfiles.profiles.client.enable;
          message = "Audio is for clients";
        };
        home-manager.sharedModules = [
          ({pkgs, ...}: {
            home.packages = with pkgs;
              mkMerge [
                [helvum pavucontrol qpwgraph perSystem.inputs'.wiremix.packages.wiremix]
                (mkIf (stdenv.hostPlatform.system != "aarch64-linux") [spotify])
              ];
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
