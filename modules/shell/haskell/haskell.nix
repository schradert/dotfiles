{
  # TODO should hoogle run locally or remote?
  canivete.deploy.system.homeModules.haskell = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
    inherit (config.dotfiles.programs) haskell;
  in {
    options.dotfiles.programs.haskell = {
      enable = mkEnableOption "haskell";
      emacs.enable = mkEnableOption "haskell integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "haskell integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf haskell.enable (mkMerge [
      (mkIf haskell.emacs.enable {
        dotfiles.programs.emacs = {
          dependencies = with pkgs.haskellPackages; [haskell-language-server hoogle cabal-install];
          orgFiles = [./haskell.org];
        };
      })
      (mkIf haskell.vim.enable {programs.vim.plugins = [pkgs.vimPlugins.haskell-with-unicode-vim];})
    ]);
  };
}
