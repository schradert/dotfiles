{inputs, ...}: {
  flake.overlays.unison = inputs.unison.overlays.default;
  dotfiles.home-manager = {pkgs, ...}: {
    # TODO where to include tree-sitter plugin tree-sitter-unison?
    # TODO rss: https://www.unison-lang.org/blog/
    # programs.emacs.extraPackages = epkgs: [epkgs.unison-ts-mode];
    programs.vim.plugins = with pkgs.vimPlugins; [vim-unison];
  };
}
