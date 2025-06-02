{
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: let
    inherit (flake.config.canivete.meta) domain;
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
      # FIXME build to work on darwin
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
