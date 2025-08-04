{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.haskell.enable = lib.mkEnableOption "haskell";
    config = lib.mkIf config.dotfiles.programs.haskell.enable {
      programs.vim.plugins = [pkgs.vimPlugins.haskell-with-unicode-vim];
      programs.doom-emacs = {
        tangle.init.lang.haskell = ["+lsp" "+tree-sitter"];
        tangle.config = "(after! lsp-haskell (setq lsp-haskell-formatting-provider \"brittany\"))";
        extraBinPackages = with pkgs.haskellPackages; [
          haskell-language-server
          cabal-install
          # TODO should hoogle run locally or remote?
          hoogle
        ];
      };
    };
  };
}
