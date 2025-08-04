{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.kotlin.enable = lib.mkEnableOption "kotlin";
    config = lib.mkIf config.dotfiles.programs.kotlin.enable {
      home.packages = [pkgs.kotlin];
      programs.doom-emacs.extraBinPackages = with pkgs; [kotlin-language-server ktlint];
      programs.doom-emacs.tangle.init.lang.kotlin = ["+lsp"];
      programs.vim.plugins = [pkgs.vimPlugins.kotlin-vim];
    };
  };
}
