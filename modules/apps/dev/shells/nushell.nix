{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.nushell.sources = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Command to generate nushell integration for each package name";
    };
    config = lib.mkIf config.programs.nushell.enable {
      programs.doom-emacs = {
        extraPackages = e: [e.nushell-mode];
        tangle.packages = ''
          (when (package! nushell-ts-mode :recipe (:host github :repo "herbertjones/nushell-ts-mode") :pin "e07ecc59762fab8d5fa35bc6d3f522f74e580a2f")
            (package! nushell-ts-babel :recipe (:host github :repo "herbertjones/nushell-ts-babel") :pin "17da6b0144502b0f0f182585bfcf53274fed238b"))
        '';
        tangle.config = ''
          (after! nushell-ts-mode
            (require 'nushell-ts-babel)
            (add-hook 'nushell-ts-mode-local-vars-hook #'tree-sitter! 'append))
        '';
      };
      programs.nushell = lib.mkMerge (lib.flip lib.mapAttrsToList config.dotfiles.programs.nushell.sources (name: cmd: {
        extraConfig = "source ${pkgs.runCommand "${name}.nu" {} "${cmd} >> $out"}";
      }));
    };
  };
}
