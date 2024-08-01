{nix, ...}:
with nix; {
  canivete.deploy.system.homeModules.editor.options.dotfiles.editor = mkOption {
    type = enum ["vim" "emacs"];
    default = "vim";
    example = "emacs";
    description = "Default editor to use for profile";
  };
}
