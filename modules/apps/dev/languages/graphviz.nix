{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.graphviz.enable = lib.mkEnableOption "graphviz";
    config = lib.mkIf config.dotfiles.programs.graphviz.enable {
      home.packages = [pkgs.graphviz];
      programs.doom-emacs.tangle.init.lang.graphviz = true;
      programs.vim.plugins = [pkgs.vimPlugins.graphviz-vim];
    };
  };
}
