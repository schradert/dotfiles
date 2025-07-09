{
  config,
  inputs,
  ...
}: {
  dotfiles.nixos = {
    config,
    lib,
    node,
    ...
  }: {
    imports = [inputs.nixos-facter-modules.nixosModules.facter];
    options.dotfiles.facter.reportName = lib.mkOption {
      type = lib.types.str;
      default = node.name;
      description = "Name of JSON file with report";
    };
    # Basically everything on-prem has this but facter misses it...
    config.boot.initrd.availableKernelModules = ["usbhid"];
    config.facter.reportPath = lib.mkDefault (inputs.self + "/infra/nodes/nixos/${config.dotfiles.facter.reportName}.json");
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
