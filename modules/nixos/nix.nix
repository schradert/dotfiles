{inputs, ...}: {
  dotfiles.nixos = {
    home-manager.sharedModules = [
      inputs.nix-index-database.hmModules.nix-index
      ({
        config,
        pkgs,
        ...
      }: {
        home.packages = with pkgs; [nix-inspect nix-fast-build];
        nix.extraOptions = "experimental-features = nix-command flakes";
        programs.nix-index.package = pkgs.nix-index-with-db;
        programs.nix-index-database.comma.enable = true;
        programs.nushell.extraConfig = "$env.config.hooks.command_not_found = source ${config.programs.nix-index.package}/etc/profile.d/command-not-found.nu";
        # TODO elvish + xonsh adapters for command-not-found hook
      })
    ];
    # Nushell script isn't packaged yet or updated to removed --top-level
    nixpkgs.overlays = [
      inputs.nix-index-database.overlays.nix-index
      (final: prev: {
        nix-index-unwrapped = inputs.nix-index.packages.${prev.system}.default;
        nix-index-with-db = prev.nix-index-with-db.overrideAttrs (old: {
          buildCommand =
            old.buildCommand
            + ''
              rm -f "$out/etc/profile.d/command-not-found.nu"
              substitute \
                "${final.nix-index-unwrapped}/etc/profile.d/command-not-found.nu" \
                "$out/etc/profile.d/command-not-found.nu" \
                --replace-fail "${final.nix-index-unwrapped}" "$out"
              sed --in-place '32s/--top-level //' "$out/etc/profile.d/command-not-found.nu"
            '';
        });
      })
    ];
  };
}
