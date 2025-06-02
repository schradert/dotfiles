{
  dotfiles = {
    shared = {lib, ...}: {
      options.dotfiles.programs.godot.enable = lib.mkEnableOption "godot";
    };
    darwin = {
      config,
      lib,
      ...
    }: {
      homebrew.casks = lib.mkIf config.dotfiles.programs.godot.enable ["godot"];
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (config.dotfiles.programs) godot;
      inherit (lib) mkEnableOption mkIf mkMerge mkPackageOption;
      inherit (pkgs.stdenv.hostPlatform) isLinux;
    in {
      options.dotfiles.programs.godot = {
        package = mkPackageOption pkgs "godot_4" {};
        demo.enable = mkEnableOption "example game" // {default = isLinux;};
        emacs.enable = mkEnableOption "godot integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
        vim.enable = mkEnableOption "godot integration in vim" // {default = config.programs.vim.enable;};
        vim.package = mkPackageOption pkgs ["vimPlugins" "vim-godot"] {};
      };
      config = mkIf godot.enable (mkMerge [
        (mkIf godot.emacs.enable {
          home.packages = [pkgs.gdtoolkit_4];
          dotfiles.programs.emacs.orgFiles = [./godot.org];
        })
        (mkIf godot.vim.enable {
          programs.vim.plugins = [godot.vim.package];
        })
        (mkIf isLinux {
          home.packages = mkMerge [
            [godot.package]
            (mkIf godot.demo.enable [pkgs._4d-minesweeper])
          ];
        })
      ]);
    };
  };
}
