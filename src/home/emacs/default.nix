{ pkgs, flake, lib, ... }:
# let doom-config-dir = import ./doom.d { inherit pkgs; };
# in
{
  home.packages = with pkgs; [
    cargo
    editorconfig-core-c
    gopls
    gotools
    gomodifytags
    gore
    gotests
    gnugrep
    graphviz
    haskellPackages.haskell-language-server
    haskellPackages.hoogle
    haskellPackages.cabal-install
    imagemagick
    ispell
    isync
    ktlint
    mu
    nil
    nixfmt
    nodePackages.js-beautify
    nodePackages.stylelint
    pandoc
    pipenv
    python311Packages.grip
    python311Packages.isort
    python311Packages.nose
    python311Packages.pytest
    rust-analyzer
    rustc
    shellcheck
    taplo
    sqls
  ] ++ lib.optionals (pkgs.system == "darwin") [
      pngpaste
  ];
# TODO (Tristan): figure out why none of this works correctly
# home.activation.doomInstallation = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
#   if ! command -v doom &>/dev/null; then
#     ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   fi
#   ~/.config/emacs/bin/doom install
# '';
# imports = [ flake.inputs.nix-doom-emacs.hmModule ];
# home.file.".doom.d".source = doom-config-dir;
# programs.emacs = {
#   enable = true;
#   package = pkgs.emacs29-pgtk;
# };
# programs.doom-emacs = rec {
#   enable = true;
#   emacsPackage = pkgs.emacs29-pgtk;
#   doomPrivateDir = doom-config-dir;
#    doomPackageDir =
#      let
#        filtered-path = builtins.path {
#          path = doomPrivateDir;
#          name = "doom-private-dir-filtered";
#          filter = path: _: builtins.elem (builtins.baseNameOf path) [ "init.el" "packages.el" ];
#        };
#        packages = [
#          { name = "init.el"; path = "${filtered-path}/init.el"; }
#          { name = "packages.el"; path = "${filtered-path}/packages.el"; }
#          { name = "config.el"; path = pkgs.emptyFile; }
#        ];
#      in pkgs.linkFarm "doom-packages-dir" packages;
# };
}
