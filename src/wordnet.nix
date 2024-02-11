{moduleWithSystem, ...}: {
  perSystem = {pkgs, ...}: {
    packages.wordnet = pkgs.wordnet.overrideAttrs (old: {
      patchPhase =
        old.patchPhase
        + ''
          sed '132s/^/int /' -i src/wn.c
        '';
    });
  };
  flake.homeModules.wordnet = moduleWithSystem ({self', ...}: {
    home.packages = [self'.packages.wordnet];
  });
}
