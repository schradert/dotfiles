{
  perSystem.canivete.pre-commit.settings.hooks.typos.settings.ignored-words = ["ein"];
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkPackageOption;
    inherit (config.dotfiles.programs) python;
  in {
    options.dotfiles.programs.python = {
      enable = mkEnableOption "python";
      package = mkPackageOption pkgs "python3" {};
      emacs.enable = mkEnableOption "python integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "python integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf python.enable (mkMerge [
      {home.packages = [python.package];}
      (mkIf python.emacs.enable {
        dotfiles.programs.emacs = {
          dependencies = let
            # TODO how to get ptvsd?
            packages = ppkgs: with ppkgs; [isort pytest jupyter debugpy];
          in [pkgs.pyright pkgs.pipenv (python.package.withPackages packages)];
          orgFiles = [./python.org];
        };
      })
      (mkIf python.vim.enable {programs.vim.plugins = [pkgs.vimPlugins.python-mode];})
    ]);
  };
}
