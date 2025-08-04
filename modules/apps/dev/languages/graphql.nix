{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.graphql.enable = lib.mkEnableOption "graphql";
    config = lib.mkIf config.dotfiles.programs.graphql.enable {
      programs.doom-emacs.tangle.init.lang.graphql = ["+lsp"];
      programs.doom-emacs.extraBinPackages = [pkgs.nodePackages.graphql-language-service-cli];
      programs.vim.plugins = [pkgs.vimPlugins.vim-graphql];
    };
  };
}
