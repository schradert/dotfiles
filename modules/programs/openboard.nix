{nix, ...}: with nix; {
  canivete.deploy.droid.modules = {config, pkgs, ...}: let
    inherit (config.dotfiles.programs) heliboard;
  in {
    config = mkIf heliboard.enable {environment.packages = [heliboard.package];};
    options.dotfiles.programs.heliboard = {
      enable = mkEnabledOption "HeliBoard keyboard application";
      # TODO convert this to gradle build in nix
      # NOTE how to use gradlew? do I need gradle2nix/v2? can I do it from scratch?
      package = mkOption {
        type = package;
        description = "Package to include in environment";
        default = pkgs.fetchurl {
          url = "https://github.com/Helium314/HeliBoard/releases/download/v2.2/HeliBoard_2.2-release.apk";
          hash = "sha256-GIHjs4nL363OMN4GAmOn38rRHT0NQ6RLb41952QePYA=";
        };
      };
    };
  };
}
