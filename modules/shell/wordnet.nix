{
  flake.overlays.wordnet = _: prev: {
    wordnet = prev.wordnet.overrideAttrs (old: {
      patchPhase = old.patchPhase + "\nsed '132s/^/int /' -i src/wn.c\n";
    });
  };
  canivete.deploy.system.homeModules.wordnet = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.wordnet = {
      enable = lib.mkEnableOption "WordNet lexical database CLI";
      package = lib.mkPackageOption pkgs "wordnet" {};
    };
    config.home.packages = lib.mkIf config.dotfiles.programs.wordnet.enable [pkgs.wordnet];
    # TODO create a TUI to navigate this better
    # TODO how can I create a TUI with open-english-wordnet and the globalwordnet? (OMW)
  };
}
