{ self, ... }:
{
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
  ];

  networking.hostName = "chilldom";
  networking.wireless.enable = true;
  networking.wireless.networks.lanyard.psk = "bruhWHY123!";
}
