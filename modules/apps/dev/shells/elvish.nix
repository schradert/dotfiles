{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) elvish;
  in {
    options.dotfiles.programs.elvish = {
      enable = lib.mkEnableOption "elv.sh";
      package = lib.mkPackageOption pkgs "elvish" {};
      interactiveExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Lines in rc.elv";
      };
    };
    config = lib.mkIf elvish.enable {
      home.packages = [elvish.package];
      programs.doom-emacs.extraPackages = e: [e.ob-elvish e.elvish-mode];
      programs.vim.plugins = [pkgs.vimPlugins.elvish-vim];
      xdg.configFile."elvish/rc.elv".source = pkgs.writeText "rc.elv" elvish.interactiveExtra;

      # TODO https://github.com/ejrichards/mellon
      # TODO should I populate a lot of variables using pkgs.bash-env-json?
      # NOTE borrowed a lot from https://github.com/zzamboni/dot-elvish/blob/master/rc.org
      # TODO build plugins and add them to XDG_DATA_HOME
      # NOTE https://elv.sh/ref/epm.html
      # NOTE https://github.com/zzamboni/dot-elvish/blob/master/rc.org#package-installation
    };
  };
}
