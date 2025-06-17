{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) xonsh;
    inherit (lib) forEach mkEnableOption mkOption mkPackageOption mkIf mkMerge types;
  in {
    options.dotfiles.programs.xonsh = {
      enable = mkEnableOption "xonsh";
      package = mkPackageOption pkgs "xonsh" {};
      packages = mkOption {
        default = _: [];
        description = "Packages/extensions to provide with xonsh";
        type = lib.hm.types.selectorFunction;
      };
      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Lines in .xonshrc";
      };
      # TODO is this even necessary? look at NixOS xonsh module
      xontribs = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Tools to load with xontrib";
      };
    };
    config = mkIf xonsh.enable {
      home.packages = [(xonsh.package.override {extraPackages = xonsh.packages;})];
      dotfiles.programs.emacs.orgFiles = [./xonsh.org];
      xdg.configFile."xonsh/.xonshrc".source = pkgs.writeText ".xonshrc" xonsh.initExtra;
      dotfiles.programs.xonsh.initExtra = mkMerge (forEach xonsh.xontribs (pkg: "xontrib load ${pkg}"));
    };
  };
}
