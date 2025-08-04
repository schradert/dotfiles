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
    }: {
      config = lib.mkIf config.dotfiles.programs.godot.enable {
        programs.vim.plugins = [pkgs.vimPlugins.vim-godot];
        programs.doom-emacs.extraBinPackages = [pkgs.gdtoolkit_4];
        programs.doom-emacs.tangle.init.lang.gdscript = ["+lsp"];
        home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [pkgs.godot];
      };
    };
  };
}
