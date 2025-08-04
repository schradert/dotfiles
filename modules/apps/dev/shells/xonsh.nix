{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) xonsh;
  in {
    options.dotfiles.programs.xonsh = {
      enable = lib.mkEnableOption "xonsh";
      package = lib.mkPackageOption pkgs "xonsh" {};
      packages = lib.mkOption {
        default = _: [];
        description = "Packages/extensions to provide with xonsh";
        type = lib.hm.types.selectorFunction;
      };
      interactiveExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Lines in .xonshrc";
      };
    };
    config = lib.mkIf xonsh.enable {
      home.packages = [(xonsh.package.override {extraPackages = xonsh.packages;})];
      programs.doom-emacs.extraPackages = e: [e.xonsh-mode];
      xdg.configFile."xonsh/rc.xsh".source = pkgs.writeText "rc.xsh" ''
        if __xonsh__.env.get("XONSH_INTERACTIVE"):
            ${xonsh.interactiveExtra}
      '';
      xdg.configFile."xonsh/.xonshrc".source = pkgs.writeText ".xonshrc" xonsh.interactiveExtra;
    };
  };
}
