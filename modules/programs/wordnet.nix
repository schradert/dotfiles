{
  canivete.deploy.system.homeModules.wordnet = {pkgs, ...}: let
    wordnet = pkgs.wordnet.overrideAttrs (old: {
      patchPhase = old.patchPhase + "\nsed '132s/^/int /' -i src/wn.c\n";
    });
  in {
    home.packages = [wordnet];
  };
}
