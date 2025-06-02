{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkPackageOption;
    inherit (config.dotfiles.programs) zig;
  in {
    options.dotfiles.programs.zig = {
      enable = mkEnableOption "zig";
      package = mkPackageOption pkgs "zig" {};
      emacs.enable = mkEnableOption "zig integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "zig integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf zig.enable {
      home.packages = [zig.package];
      dotfiles.programs.emacs = mkIf zig.emacs.enable {
        dependencies = [pkgs.zls];
        orgFiles = [./zig.org];
      };
      programs.vim.plugins = mkIf zig.vim.enable [pkgs.vimPlugins.zig-vim];
    };
  };
}
