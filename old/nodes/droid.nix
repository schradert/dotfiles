{
  dotfiles.droid = {
    config,
    options,
    ...
  }: {
    home-manager = {
      backupFileExtension = "hm-bak";
      useGlobalPkgs = true;
      sharedModules = [
        {
          options.dotfiles = options.dotfiles;
          config.dotfiles = config.dotfiles;
        }
        ({
          config,
          lib,
          pkgs,
          ...
        }: let
          # TODO convert to gradle build in nix
          # NOTE how to use gradlew? do I need gradle2nix/v2? can I do it from scratch?
          inherit (lib) pipe filterAttrs getAttr mapAttrsToList concatStringsSep mkEnabledOption mkOption types mkIf;
          inherit (config.dotfiles) apk;
          apks = pipe apk.programs [
            (filterAttrs (getAttr "enable"))
            (mapAttrsToList (_: getAttr "apk"))
            (concatStringsSep " ")
          ];
        in {
          options.dotfiles.apk = {
            enable = mkEnabledOption "APK installation step";
            programs = mkOption {
              type = types.attrsOf (types.submodule ({name, ...}: {
                options.enable = mkEnabledOption name;
                options.apk = mkOption {type = types.package;};
              }));
              default = {};
            };
          };
          config = mkIf apk.enable {
            home.activation.apkInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
              ${pkgs.android-tools}/bin/adb install-multiple ${apks}
            '';
          };
        })
      ];
    };
    environment.etcBackupExtension = ".bak";
    system.stateVersion = "23.05";
    android-integration = {
      am.enable = true;
      termux-open.enable = true;
      termux-setup-storage.enable = true;
      termux-reload-settings.enable = true;
      termux-wake-lock.enable = true;
      xdg-open.enable = true;
      unsupported.enable = true;
    };
  };
}
