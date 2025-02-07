{
  # TODO build https://github.com/josueBarretogit/get_blessed_rs
  canivete.deploy.system.homeModules.rust = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
    inherit (config.dotfiles.programs) rust;
  in {
    options.dotfiles.programs.rust = {
      enable = mkEnableOption "rust";
      emacs.enable = mkEnableOption "rust integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "rust integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf rust.enable (mkMerge [
      {home.sessionVariables.CARGO_HOME = "${config.xdg.dataHome}/cargo";}
      (mkIf rust.emacs.enable {
        dotfiles.programs.emacs = {
          dependencies = with pkgs; [cargo rust-analyzer rustc];
          orgFiles = [./rust.org];
        };
      })
      (mkIf rust.vim.enable {programs.vim.plugins = [pkgs.vimPlugins.rust-vim];})
    ]);
  };
}
