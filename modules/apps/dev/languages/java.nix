{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.java.enable = lib.mkEnableOption "java";
    config = lib.mkIf config.dotfiles.programs.java.enable {
      programs.java.enable = true;
      programs.java.package = pkgs.jdk11;
      programs.doom-emacs.tangle.init.lang.java = ["+lsp" "+tree-sitter"];
      programs.doom-emacs.extraBinPackages = [pkgs.jdt-language-server];
    };
  };
}
