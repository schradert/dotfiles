{
  perSystem.canivete.pre-commit.settings.hooks.typos.settings.ignored-words = ["ein"];
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.python.enable = lib.mkEnableOption "python";
    config = lib.mkIf config.dotfiles.programs.python.enable {
      programs.vim.plugins = [pkgs.vimPlugins.python-mode];
      programs.doom-emacs = {
        tangle = {
          init.lang.org = ["+jupyter"];
          init.lang.python = ["+lsp" "+pyright" "+tree-sitter"];
          init.tools.ein = true;
          packages = "(package! nose :disable t)";
        };
        extraBinPackages = let
          # TODO how to get ptvsd?
          packages = ppkgs: with ppkgs; [isort pytest jupyter debugpy];
        in [pkgs.pyright pkgs.pipenv (pkgs.python3.withPackages packages)];
      };
    };
  };
}
