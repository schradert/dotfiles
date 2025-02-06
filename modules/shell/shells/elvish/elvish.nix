{
  canivete.deploy.system.homeModules.elvish = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) elvish;
    inherit (lib) forEach mkEnableOption mkMerge mkOption mkPackageOption mkIf types;
  in {
    options.dotfiles.programs.elvish = {
      enable = mkEnableOption "elv.sh";
      package = mkPackageOption pkgs "elvish" {};
      integrations = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Commands to eval in config.elv";
      };
      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Lines in config.elv";
      };
    };
    config = mkIf elvish.enable {
      home.packages = [elvish.package];
      programs.vim.plugins = [pkgs.vimPlugins.elvish-vim];
      xdg.configFile."elvish/rc.elv" = pkgs.writeText "rc.elv" elvish.initExtra;

      dotfiles.programs.emacs.orgFiles = [./elvish.org];
      dotfiles.programs.elvish.initExtra = mkMerge (forEach elvish.integrations (cmd: "eval (${cmd})"));

      # TODO https://github.com/ejrichards/mellon
      # TODO should I populate a lot of variables using pkgs.bash-env-json?
      # NOTE borrowed a lot from https://github.com/zzamboni/dot-elvish/blob/master/rc.org
      # TODO build plugins and add them to XDG_DATA_HOME
      # NOTE https://elv.sh/ref/epm.html
      # NOTE https://github.com/zzamboni/dot-elvish/blob/master/rc.org#package-installation
    };
  };
}
