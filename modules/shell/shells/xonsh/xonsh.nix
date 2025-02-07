{
  # NOTE https://github.com/anki-code/xonsh-cheatsheet
  # TODO probably doesn't work yet as a login shell https://discourse.nixos.org/t/can-i-use-xonsh-as-my-login-shell-if-so-how/6472
  # TODO https://github.com/xonsh/awesome-xontribs
  # TODO https://github.com/xonsh/xontrib-jupyter
  # TODO https://github.com/anki-code/xontrib-output-search
  # TODO https://github.com/xxh/xxh-shell-xonsh
  # TODO https://github.com/anki-code/xontrib-prompt-starship
  # TODO https://github.com/anki-code/xontrib-sh
  # TODO https://github.com/anki-code/xontrib-pipeliner
  # TODO https://xon.sh/xonshrc.html
  canivete.deploy.nixos.modules.xonsh.programs.xonsh = {
    enable = true;
    config = "";
  };
  canivete.deploy.system.homeModules.xonsh = {
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
      xontribs = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Tools to load with xontrib";
      };
    };
    config = mkIf xonsh.enable {
      home.packages = [(xonsh.package.override {extraPackages = xonsh.packages config.dotfiles.programs.python.package.pkgs;})];
      dotfiles.programs.emacs.orgFiles = [./xonsh.org];
      xdg.configFile."xonsh/.xonshrc" = pkgs.writeText ".xonshrc" xonsh.initExtra;
      dotfiles.programs.xonsh.initExtra = mkMerge (forEach xonsh.xontribs (pkg: "xontrib load ${pkg}"));
    };
  };
}
