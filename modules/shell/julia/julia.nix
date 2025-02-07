{
  canivete.deploy.system.homeModules.julia = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkPackageOption;
    inherit (config.dotfiles.programs) julia;
  in {
    options.dotfiles.programs.julia = {
      enable = mkEnableOption "julia";
      # NOTE julia not supported on darwin but binaries are
      package = mkPackageOption pkgs (
        if pkgs.stdenv.hostPlatform.isLinux
        then "julia"
        else "julia-bin"
      ) {};
      emacs.enable = mkEnableOption "julia integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "julia integration in vim" // {default = config.programs.vim.enable;};
      vim.plugin = mkPackageOption pkgs ["vimPlugins" "julia-vim"] {};
    };
    config = mkIf julia.enable {
      home.packages = [julia.package];
      dotfiles.programs.emacs = mkIf julia.emacs.enable {
        dependencies = [(julia.package.withPackages ["LanguageServer" "SymbolServer"])];
        orgFiles = [./julia.org];
      };
      programs.vim.plugins = mkIf julia.vim.enable [julia.vim.plugin];
    };
  };
}
