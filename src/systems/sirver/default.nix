{ self, ... }:
{
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
  ];

  networking.hostName = "sirver";
}
