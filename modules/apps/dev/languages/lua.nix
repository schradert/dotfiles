{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) lua;
  in {
    options.dotfiles.programs.lua = {
      enable = lib.mkEnableOption "lua";
      fennel.enable = lib.mkEnableOption "fennel";
      moonscript.enable = lib.mkEnableOption "moonscript";
    };
    config = lib.mkIf lua.enable (lib.mkMerge [
      {
        home.packages = [pkgs.lua];
        programs.vim.plugins = [pkgs.vimPlugins.vim-lua];
        # TODO is it a problem to not set lua-lsp-dir globally
        # TODO do I need to set lsp-clients-lua-language-server-bin to use lua-language-server?
        programs.doom-emacs.extraBinPackages = [pkgs.lua-language-server];
        programs.doom-emacs.tangle.init.lang.lua = ["+fennel" "+lsp" "+tree-sitter" "+moonscript"];
      }
      (lib.mkIf lua.fennel.enable {
        home.packages = [pkgs.lua52Packages.fennel];
        programs.vim.plugins = [pkgs.vimPlugins.fennel-vim];
      })
      (lib.mkIf lua.moonscript.enable {
        home.packages = [pkgs.lua52Packages.moonscript];
        programs.vim.plugins = [pkgs.vimPlugins.moonscript-vim];
      })
    ]);
  };
}
