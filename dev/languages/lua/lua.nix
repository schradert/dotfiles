{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkPackageOption;
    inherit (config.dotfiles.programs) lua;
  in {
    options.dotfiles.programs.lua = {
      enable = mkEnableOption "lua";
      package = mkPackageOption pkgs "lua" {};
      fennel.enable = mkEnableOption "fennel";
      fennel.package = mkPackageOption pkgs ["lua52Packages" "fennel"] {};
      moonscript.enable = mkEnableOption "moonscript";
      moonscript.package = mkPackageOption pkgs ["lua52Packages" "moonscript"] {};
      emacs.enable = mkEnableOption "lua integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "lua integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf lua.enable (mkMerge [
      {
        home.packages = [lua.package];
        programs.vim.plugins = mkIf lua.vim.enable [pkgs.vimPlugins.vim-lua];
        dotfiles.programs.emacs = mkIf lua.emacs.enable {
          dependencies = [pkgs.lua-language-server];
          orgFiles = [./lua.org];
        };
      }
      (mkIf lua.fennel.enable {
        home.packages = [lua.fennel.package];
        programs.vim.plugins = mkIf lua.vim.enable [pkgs.vimPlugins.fennel-vim];
      })
      (mkIf lua.moonscript.enable {
        home.packages = [lua.moonscript.package];
        programs.vim.plugins = mkIf lua.vim.enable [pkgs.vimPlugins.moonscript-vim];
      })
    ]);
  };
}
