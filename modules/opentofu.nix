{
  canivete,
  config,
  inputs,
  lib,
  ...
}: {
  dotfiles = _: {
    options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
    config.opentofu = {
      plugins = ["linyinfeng/shell"];
      modules = {pkgs, ...}: {
        provider.shell.interpreter = [(lib.getExe pkgs.bash) "-c"];
      };
    };
    config.nixos = {config, ...}: {
      nixpkgs.overlays = [inputs.mynur.overlays.pug];
      dotfiles.nixpkgs.config.allowUnfreePackages = lib.mkIf config.dotfiles.profiles.client.workstation.enable ["terraform"];
    };
    config.home-manager = {
      config,
      pkgs,
      ...
    }: {
      imports = [inputs.mynur.homeManagerModules.pug];
      config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
        home.packages = [pkgs.tftui pkgs.terraform];
        programs.pug.enable = true;
        programs.doom-emacs.tangle.init.tools.terraform = ["+lsp"];
      };
    };
  };
  perSystem.canivete.opentofu.workspaces = {
    bootstrap.encryptedState.enable = false;
    deploy = _: {imports = [config.dotfiles.opentofu];};
  };
}
