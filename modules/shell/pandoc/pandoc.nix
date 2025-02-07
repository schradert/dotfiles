{
  # TODO configure defaults https://pandoc.org/MANUAL.html
  canivete.deploy.system.homeModules.pandoc = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
    inherit (config.dotfiles.programs) pandoc;
  in {
    options.dotfiles.programs.pandoc = {
      enable = mkEnableOption "pandoc";
      markdown.enable = mkEnableOption "markdown support" // {default = true;};
      plantuml.enable = mkEnableOption "plantuml support" // {default = true;};
      emacs.enable = mkEnableOption "pandoc integration in emacs" // {default = config.dotfiles.programs.emacs.enable;};
      vim.enable = mkEnableOption "pandoc integration in vim" // {default = config.programs.vim.enable;};
    };
    config = mkIf pandoc.enable {
      programs.pandoc.enable = true;
      dotfiles.programs.emacs = mkIf pandoc.emacs.enable {
        dependencies = with pkgs;
          mkMerge [
            (mkIf pandoc.markdown.enable [markdownlint-cli2 textlint])
            (mkIf pandoc.plantuml.enable [plantuml pandoc-plantuml-filter])
          ];
        orgFiles = mkMerge [
          (mkIf pandoc.markdown.enable [./markdown.org])
          (mkIf pandoc.plantuml.enable [./plantuml.org])
        ];
      };
      programs.vim.plugins = mkIf pandoc.vim.enable (with pkgs.vimPlugins; mkMerge [
        [vimpreviewpandoc vim-pandoc-syntax vim-pandoc]
        (mkIf pandoc.markdown.enable [vim-markdown-toc vim-markdown])
        (mkIf pandoc.plantuml.enable [plantuml-syntax])
      ]);
    };
  };
}
