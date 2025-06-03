{
  canivete.deploy.nodes = let
    module = {pkgs, ...}: {
      dotfiles.programs.apk.heliboard.apk = pkgs.fetchurl {
        url = "https://github.com/Helium314/HeliBoard/releases/download/v2.2/HeliBoard_2.2-release.apk";
        hash = "sha256-GIHjs4nL363OMN4GAmOn38rRHT0NQ6RLb41952QePYA=";
      };
    };
  in {
    pixel.canivete.os = "android";
    pixel.profiles.home-manager.canivete.configuration = module;
    boox.canivete.os = "android";
    boox.profiles.home-manager.canivete.configuration = module;
    odin.canivete.os = "android";
    odin.profiles.home-manager.canivete.configuration = module;
    s21.canivete.os = "android";
    s21.profiles.home-manager.canivete.configuration = module;
    a10e.canivete.os = "android";
    a10e.profiles.home-manager.canivete.configuration = module;
    vivo.canivete.os = "android";
    vivo.profiles.home-manager.canivete.configuration = module;
  };
}
