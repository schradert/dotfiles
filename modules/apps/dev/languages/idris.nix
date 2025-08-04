{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.idris.enable = lib.mkEnableOption "idris";
    config = lib.mkIf config.dotfiles.programs.idris.enable {
      programs.doom-emacs = {
        tangle.init.lang.idris = ["+lsp"];
        tangle.config = "(after! idris-mode (setq idris-interpreter-path \"idris2\"))";
        extraBinPackages = [pkgs.idris2Packages.idris2Lsp];
      };
      home.packages = [pkgs.idris2];
      programs.vim.plugins = [pkgs.vimPlugins.idris2-vim];
    };
  };
}
