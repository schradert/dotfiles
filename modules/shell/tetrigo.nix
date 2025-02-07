{
  # TODO build https://github.com/ringtailsoftware/zigtris
  flake.overlays.tetrigo = final: _: {
    tetrigo = final.callPackage ({
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
      buildGoModule rec {
        pname = "tetrigo";
        version = lib.substring 0 7 src.rev;
        src = fetchFromGitHub {
          owner = "Broderick-Westrope";
          repo = "tetrigo";
          rev = "fa956f6c4b2cdd38ef9bdde6a5eb01d9009445ed";
          hash = "sha256-J4sWSAYV1QhaGVZuKlMg/Kf/f/Kii5o7wRZu8cIRgnA=";
        };
        vendorHash = "sha256-DUi09cd6Bi6RHrd9C/uFab4LhffJtU3IUv1GMgs65+8=";
        meta = {
          mainProgram = "tetrigo";
          homepage = "";
          description = "";
          license = lib.licenses.gpl3Only;
        };
      }) {};
  };
  canivete.deploy.system.homeModules.tetrigo = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) tetrigo;
    inherit (lib) mkEnableOption mkPackageOption mkOption mkIf;
    toml = pkgs.formats.toml {};
  in {
    options.dotfiles.programs.tetrigo = {
      enable = mkEnableOption "tetrigo";
      package = mkPackageOption pkgs "tetrigo" {};
      config = mkOption {
        inherit (toml) type;
        default = {};
        description = "Structured contents of config.toml";
      };
    };
    config = mkIf tetrigo.enable {
      home.packages = [tetrigo.package];
      xdg.configFile = mkIf (tetrigo.config != {}) {"tetrigo/config.toml".source = toml.generate "tetrigo.config.toml" tetrigo.config;};
      dotfiles.programs.tetrigo.config = {
        # TODO go through all of the settings I want to change
      };
    };
  };
}
