{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.workstation.enable {
      home.packages = with pkgs; [
        carapace
        zx
      ];
      programs.fish.enable = true;
    };
  };
}
