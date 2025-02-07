{
  # TODO consider https://github.com/pd3v/line
  # TODO package https://github.com/overtone/overtone
  # TODO package https://github.com/khtdr/glicol-mode
  # TODO package https://gitlab.com/iShapeNoise/foxdot as PitchGlitch instead of foxdot
  canivete.deploy.system.modules.synth = {lib, ...}: {
    options.dotfiles.graphical.sound.synth.enable = lib.mkEnableOption "synthesizing tools";
  };
  canivete.deploy.darwin.modules.synth = {config, lib, ...}: {
    config = lib.mkIf config.dotfiles.graphical.sound.synth.enable {
      homebrew.casks = ["supercollider"];
    };
  };
  canivete.deploy.system.homeModules.synth = {config, lib, pkgs, ...}: {
    config = lib.mkIf config.dotfiles.graphical.sound.synth.enable {
      home.packages = lib.mkMerge [
        (with pkgs; [glicol-cli faust])
        # TODO should I investigate all of these haskell packages to work with supercollider?
        # TODO would I ever want _scel (emacs lisp?)?
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux [pkgs.supercollider-with-sc3-plugins])
      ];
      dotfiles.programs.emacs.orgFiles = [./sound.org];
    };
  };
}
