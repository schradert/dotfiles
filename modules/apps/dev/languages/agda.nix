{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.agda.enable = lib.mkEnableOption "agda";
    config = lib.mkIf config.dotfiles.programs.agda.enable {
      home.packages = [pkgs.agda];
      programs.vim.plugins = [pkgs.vimPlugins.vim-agda];
      programs.doom-emacs.tangle.init.lang.agda = ["+local" "+tree-sitter"];
    };
  };
}
