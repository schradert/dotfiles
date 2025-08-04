{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.javascript.enable = lib.mkEnableOption "nodejs";
    config = lib.mkIf config.dotfiles.programs.javascript.enable {
      home.packages = [pkgs.nodejs];
      programs.doom-emacs.extraBinPackages = with pkgs; [nodePackages.js-beautify nodePackages.stylelint];
      programs.doom-emacs.tangle.init.lang.javascript = ["+lsp" "+tree-sitter"];
      programs.vim.plugins = [pkgs.vimPlugins.vim-javascript];
    };
  };
}
