{
  # TODO convert to input-leap
  # TODO build to work on darwin
  canivete.deploy.nixos.modules.barrier = {config, flake, lib, pkgs, ...}: let
    inherit (flake.config.dotfiles) domain;
    inherit (lib) mkEnableOption mkIf mkMerge;
    inherit (pkgs) barrier stdenv;
  in {
    options.dotfiles.programs.barrier.enable = mkEnableOption "Barrier KVM";
    config = mkIf config.dotfiles.programs.barrier.enable (mkMerge [
      {
        home.packages = [barrier];
      }
      (mkIf stdenv.isLinux {
        services.barrier.client = {
          enable = true;
          enableDragDrop = true;
          server = domain;
        };
      })
      (mkIf stdenv.isDarwin {
        launchd.agents.barrier = {
          enable = true;
          config = {
            RunAtLoad = true;
            KeepAlive.Crashed = true;
            Program = "${barrier}/bin/barrierc";
            ProgramArguments = ["--enable-drag-drop" "-f" domain];
          };
        };
      })
    ]);
  };
}
