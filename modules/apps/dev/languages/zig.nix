{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.zig.enable = lib.mkEnableOption "zig";
    config = lib.mkIf config.dotfiles.programs.zig.enable {
      home.packages = [pkgs.zig];
      programs.doom-emacs.extraBinPackages = [pkgs.zls];
      programs.doom-emacs.tangle.init.lang.zig = ["+lsp" "+tree-sitter"];
      programs.vim.plugins = [pkgs.vimPlugins.zig-vim];
    };
  };
}
