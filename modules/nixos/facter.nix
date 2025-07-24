{
  canivete,
  config,
  inputs,
  ...
}: {
  dotfiles = _: {
    options.nodes = canivete.mkNestedSubmodule ({
      config,
      lib,
      name,
      ...
    }: {
      config = lib.mkIf (config.platform ? prem) {
        system.imports = [inputs.nixos-facter-modules.nixosModules.facter];
        # Basically everything on-prem has this but facter misses it...
        system.boot.initrd.availableKernelModules = ["usbhid"];
        system.facter.reportPath = inputs.self + "/infra/nodes/nixos/${name}.json";
      };
    });
  };
  perSystem = {pkgs, ...}: {
    # TODO make this a real thing (platforms, variables, ...)
    apps.fetch-facter = pkgs.writeShellApplication {
      name = "fetch-facter";
      text = ''
        hcloud ssh-key create --name test --public-key-from-file ${inputs.self + "/.canivete/sops/${config.canivete.meta.people.me}.pub"}
        hcloud server create --name test --type cpx11 --image debian-12 --ssh-key test
        hcloud server ssh test -- 'curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm'
        hcloud server ssh test -- nix run github:nix-community/nixos-facter > cpx11.json
        hcloud server delete test
        hcloud ssh-key delete test
      '';
    };
  };
}
