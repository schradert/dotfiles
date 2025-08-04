{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # NOTE julia not supported on darwin but binaries are
    julia =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.julia
      else pkgs.julia-bin;
  in {
    options.dotfiles.programs.julia.enable = lib.mkEnableOption "julia";
    config = lib.mkIf config.dotfiles.programs.julia.enable {
      home.packages = [julia];
      programs.doom-emacs.extraBinPackages = [(julia.withPackages ["LanguageServer" "SymbolServer"])];
      programs.doom-emacs.tangle.init.lang.julia = ["+lsp" "+tree-sitter" "+snail"];
      programs.vim.plugins = [pkgs.vimPlugins.julia-vim];
    };
  };
}
