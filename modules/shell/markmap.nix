{
  flake.overlays.markmap = final: _: {
    markmap = final.callPackage ({
      lib,
      stdenv,
      fetchFromGitHub,
      pnpm_9,
      nodejs,
    }:
      stdenv.mkDerivation (finalAttrs: {
        pname = "markmap";
        version = lib.substring 0 7 finalAttrs.src.rev;
        src = fetchFromGitHub {
          owner = "markmap";
          repo = "markmap";
          rev = "6229c3c3dd16008b69b63d16003714815c0037a9";
          hash = "sha256-b6QI15jO/51Z1kmNCyrMVTIJ9H0Jy0qgj2XYBqdsciA=";
        };
        nativeBuildInputs = [nodejs pnpm_9.configHook];
        pnpmDeps = pnpm_9.fetchDeps {
          inherit (finalAttrs) pname version src;
          hash = "sha256-sP6468qmRYGVq+Vg9M+cJtCvDtJ6CBk4K7PJj8vxch4=";
        };
        meta.mainProgram = "markmap";
      })) {};
  };
  canivete.deploy.system.homeModules.markmap = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) markmap;
  in {
    options.dotfiles.programs.markmap = {
      enable = lib.mkEnableOption "markmap";
      package = lib.mkPackageOption pkgs "markmap" {};
    };
    # TODO why is this failing? (builder failed to produce output path for output 'out')
    # config = lib.mkIf markmap.enable {home.packages = [markmap.package];};
  };
}
