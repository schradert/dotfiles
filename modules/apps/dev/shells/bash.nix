{
  # TODO variables and options
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.programs.bash.enable {
      programs.doom-emacs.tangle.init.lang.sh = ["+lsp" "+tree-sitter"];
      programs.doom-emacs.extraBinPackages = with pkgs;
        lib.mkMerge [
          [bash-language-server shellcheck]
          # TODO follow https://github.com/NixOS/nixpkgs/issues/428955
          # (lib.mkIf stdenv.hostPlatform.isLinux [bashdb])
        ];
      programs.bash.historyFile = "${config.xdg.stateHome}/bash/history";
    };
  };
}
