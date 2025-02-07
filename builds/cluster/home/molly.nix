{
  # TODO https://github.com/mollyim/mollysocket
  # TODO https://github.com/signalapp/Signal-Server
  # TODO https://github.com/mautrix/signal
  # NOTE not sure how to specify a different signal network in the clients...
  canivete.deploy = {
    darwin.modules.signal = {config, lib, ...}: {
      homebrew.casks = lib.mkIf config.dotfiles.profiles.chat.enable ["signal"];
    };
    system.homeModules.signal = {config, lib, pkgs, ...}: let
      inherit (pkgs) signal-cli scli signal-desktop;
    in {
      home.packages = lib.mkIf config.dotfiles.profiles.chat.enable (lib.mkMerge [
        [signal-cli scli]
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux [signal-desktop])
      ]);
    };
  };
}
