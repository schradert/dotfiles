{
  canivete.deploy.droid.homeModules.heliboard = {pkgs, ...}: {
    dotfiles.programs.apk.heliboard.apk = pkgs.fetchurl {
      url = "https://github.com/Helium314/HeliBoard/releases/download/v2.2/HeliBoard_2.2-release.apk";
      hash = "sha256-GIHjs4nL363OMN4GAmOn38rRHT0NQ6RLb41952QePYA=";
    };
  };
}
