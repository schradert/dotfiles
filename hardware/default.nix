{
  dotfiles.home-manager = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      inxi
      onefetch
      cpufetch
      fastfetch
    ];
    programs.macchina.enable = true;
    programs.macchina.settings = {
      interface = lib.mkDefault "en0";
      theme = "Dracula";
    };
  };
}
