{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "emacs-config";
  version = "dev";
  src = pkgs.lib.sourceByRegex ./. [ "config.org" "init.el" ];

  buildInputs = with pkgs; [ emacs coreutils ];
  buildPhase = ''
    cp $src/* .
    # Tangle org files
    emacs --batch --quick \
      --load org config.org \
      --funcall org-babel-tangle
  '';
  dontUnpack = true;
  installPhase = ''
    install -D -t $out *.el
  '';
}
