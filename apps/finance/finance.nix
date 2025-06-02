{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.workstation.enable {
      # TODO test out hledger-ui and hledger-web
      home.packages = with pkgs; [
        hledger
        puffin
        ticker
        tickrs
      ];
    };
  };
}
