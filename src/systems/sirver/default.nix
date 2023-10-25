{ self, ... }:
{
  imports = [
    self.nixosModules.common
    ./hardware-configuration.nix
  ];

  networking.hostName = "sirver";
}
