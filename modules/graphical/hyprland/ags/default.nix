{
  perSystem = {inputs', pkgs, ...}: {
    packages.ags = pkgs.stdenvNoCC.mkDerivation rec {
      name = "ags";
      src = ./.;
      nativeBuildInputs = [
        inputs'.ags.packages.default
        pkgs.wrapGAppsHook
        pkgs.gobject-introspection
      ];
      buildInputs = with inputs'.astal.packages; [astal3 io];
      installPhase = ''
        mkdir -p $out/bin
        ags bundle app.ts $out/bin/${name}
      '';
    };
  };
}
