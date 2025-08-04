{
  # TODO configure defaults https://pandoc.org/MANUAL.html
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf;
    inherit (config.dotfiles.programs) pandoc;
  in {
    options.dotfiles.programs.pandoc = {
      enable = lib.mkEnableOption "pandoc";
      markdown.enable = lib.mkEnableOption "markdown support" // {default = true;};
      plantuml.enable = lib.mkEnableOption "plantuml support" // {default = true;};
    };
    config = lib.mkIf pandoc.enable {
      programs.pandoc.enable = true;
      programs.doom-emacs = lib.mkMerge [
        (mkIf pandoc.markdown.enable {
          extraBinPackages = with pkgs; [markdownlint-cli2 textlint python3Packages.grip];
          tangle.init.lang.markdown = ["+grip"];
        })
        (mkIf pandoc.plantuml.enable {
          extraBinPackages = with pkgs; [plantuml pandoc-plantuml-filter];
          tangle.init.lang.plantuml = true;
        })
      ];
      programs.vim.plugins = with pkgs.vimPlugins;
        lib.mkMerge [
          [vimpreviewpandoc vim-pandoc-syntax vim-pandoc]
          (mkIf pandoc.markdown.enable [vim-markdown-toc vim-markdown])
          (mkIf pandoc.plantuml.enable [plantuml-syntax])
        ];
    };
  };
}
