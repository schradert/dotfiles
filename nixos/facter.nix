{inputs, ...}: {
  dotfiles.nixos = {node, ...}: {
    imports = [inputs.nixos-facter-modules.nixosModules.facter];
    # Basically everything on-prem has this but facter misses it...
    boot.initrd.availableKernelModules = ["usbhid"];
    facter.reportPath = (inputs.self + "/infra/nodes/${node.name}.json");
  };
}
