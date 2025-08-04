{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.go.enable = lib.mkEnableOption "go";
    config = lib.mkIf config.dotfiles.programs.go.enable {
      programs = {
        go.enable = true;
        go.goPath = ".config/go";
        vim.plugins = with pkgs.vimPlugins; [gotests-vim vim-go];
        doom-emacs.tangle.init.lang.go = ["+lsp" "+tree-sitter"];
        doom-emacs.extraBinPackages = with pkgs; [
          gocode-gomod
          gore
          gotests
          gomodifytags
          golangci-lint
          gopls
          gotools
          delve
        ];
      };
    };
  };
}
