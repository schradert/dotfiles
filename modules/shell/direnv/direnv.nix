{
  # TODO build xonsh-direnv
  # NOTE https://github.com/74th/xonsh-direnv
  # NOTE broken
  #[ref:xonsh-direnv-build]
  perSystem.canivete.dream2nix.packages.xonsh-direnv = {
    config,
    dream2nix,
    lib,
    ...
  }: let
    inherit (config) deps mkDerivation version;
  in {
    imports = [dream2nix.modules.dream2nix.pip];
    paths.package = mkDerivation.src;
    deps = {nixpkgs, ...}: {
      inherit (nixpkgs) fetchFromGitHub;
      python = nixpkgs.python312;
    };

    name = "xonsh-direnv";
    version = "1.6.5";

    mkDerivation.src = deps.fetchFromGitHub {
      owner = "74th";
      repo = "xonsh-direnv";
      rev = version;
      hash = "";
    };
  };
  canivete.deploy.system.homeModules.direnv = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.programs.direnv.enable = lib.mkEnableOption "direnv";
    config = lib.mkIf config.dotfiles.programs.direnv.enable {
      dotfiles.programs = {
        elvish.integrations = ["${lib.getExe config.programs.direnv.package} hook elvish"];
        emacs.orgFiles = [./direnv.org];
        #[tag:xonsh-direnv-build]
        # xonsh.packages = ps: [ps.xonsh-direnv];
        xonsh.xontribs = ["direnv"];
      };
      home.sessionVariables.DIRENV_WARN_TIMEOUT = "10s";
      programs.direnv.enable = true;
      services.lorri = {
        enable = true;
        enableNotifications = true;
        nixPackage = config.nix.package;
      };
    };
  };
}
