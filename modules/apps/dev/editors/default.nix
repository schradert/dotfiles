{
  dotfiles.home-manager = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.editor = lib.mkOption {
      type = lib.types.str;
      default = "hx";
      example = "emacs";
      description = "Default editor to use for profile";
    };
    config.programs = {
      helix.enable = true;
      helix.defaultEditor = config.dotfiles.editor == "hx";
      vim.enable = true;
    };
  };
}
