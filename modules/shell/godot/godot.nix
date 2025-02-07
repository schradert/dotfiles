{lib, ...}: let
  inherit (lib) mkEnableOption mkIf mkMerge mkPackageOption;
in {
  canivete.deploy = {
    system.modules.godot.options.dotfiles.programs.godot.enable = mkEnableOption "godot";
    darwin.modules.godot = {config, ...}: {
      config.homebrew.casks = mkIf config.dotfiles.programs.godot.enable ["godot"];
    };
    nixos.homeModules.godot = {
      config,
      pkgs,
      ...
    }: let
      inherit (config.dotfiles.programs) godot;
    in {
      options.dotfiles.programs.godot = {
        package = mkPackageOption pkgs "godot_4" {};
        demo.enable = mkEnableOption "example game" // {default = true;};
      };
      config = mkIf godot.enable {
        home.packages = mkMerge [
          [godot.package]
          (mkIf godot.demo.enable [pkgs._4d-minesweeper])
        ];
      };
    };
    system.homeModules.godot = {
      config,
      pkgs,
      ...
    }: let
      inherit (config.dotfiles.programs) godot;
    in {
      options.dotfiles.programs.godot = {
        emacs.enable = mkEnableOption "godot integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
        vim.enable = mkEnableOption "godot integration in vim" // {default = config.programs.vim.enable;};
        vim.package = mkPackageOption pkgs ["vimPlugins" "vim-godot"] {};
      };
      config = mkIf godot.enable (mkMerge [
        (mkIf godot.emacs.enable {
          home.packages = [pkgs.gdtoolkit_4];
          dotfiles.programs.emacs.orgFiles = [./godot.org];
        })
        (mkIf godot.vim.enable {programs.vim.plugins = [godot.vim.package];})
      ]);
    };
  };
}
