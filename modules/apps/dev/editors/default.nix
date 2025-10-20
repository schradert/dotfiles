{
  dotfiles.home-manager = {lib, ...}: {
    options.dotfiles.editor = lib.mkOption {
      type = lib.types.str;
      default = "hx";
      example = "emacs";
      description = "Default editor to use for profile";
    };
    config.programs.vim.enable = true;
  };
}
