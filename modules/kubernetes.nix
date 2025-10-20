{
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (builtins) concatStringsSep elem filter map match readFile toString;
  inherit (lib) filterAttrs flatten flip hasSuffix mapAttrsToList mkDefault mkEnableOption mkIf mkMerge mkOption pipe toList types;
  inherit (types) attrsOf listOf package str submodule;
  mkTypeOption = type: canivete.mkOverrideOption {inherit type;};
  getGVKN = o: concatStringsSep "/" [o.apiVersion o.kind o.metadata.name];
in {
  canivete.nixidy.shared = config.dotfiles.nixidy;
  perSystem.devenv.shells.default.git-hooks = {
    excludes = ["generated"];
    hooks.lychee.toml.exclude = ["https://192.168.50.*"];
  };
  dotfiles = _: {
    options.nixidy = canivete.mkModuleOption {description = "Common nixidy configuration";};
    config = {
      home-manager = {
        config,
        nixosConfig,
        pkgs,
        ...
      }: {
        config = mkIf (config.dotfiles.profiles.client.workstation.enable || nixosConfig.canivete.kubernetes.enable) {
          home.packages = with pkgs; [kubectl kubernetes-helm kubetui kdash ktop];
          programs.kubecolor.enable = true;
          programs.doom-emacs.extraPackages = e: [e.kubernetes];
          programs.k9s.enable = true;
        };
      };
      nixos = {
        config,
        pkgs,
        ...
      }: {
        config = mkMerge [
          {
            _module.args = {inherit (inputs.nix2container.packages.${pkgs.system}) nix2container;};
            canivete.kubernetes.images.airgap = config.services.k3s.package.airgapImages;
          }
          (mkIf config.dotfiles.profiles.server.enable {
            networking.firewall.allowedTCPPorts = [6443];
            systemd.services.k3s.serviceConfig.TimeoutStartSec = 600;
          })
        ];
      };
      opentofu.modules = {perSystem, ...}: {
        resource.null_resource.kubernetes = {
          # TODO avoid hardcoding root and env names
          depends_on = ["module.nixos_sirver_system_install"];
          provisioner.local-exec.command = "nix run \${ var.GIT_DIR }#nixidyEnvs.${perSystem.system}.prod.config.build.scripts.bootstrap";
        };
      };
    };
  };
}
