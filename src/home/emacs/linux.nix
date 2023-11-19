{ pkgs, flake, lib, ... }:
# let doom-config-dir = import ./doom.d { inherit pkgs; };
# in
{
  imports = [ ./common.nix flake.inputs.nix-doom-emacs.hmModule ];
  programs.doom-emacs = { enable = true; doomPrivateDir = ./doom.d; };
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
