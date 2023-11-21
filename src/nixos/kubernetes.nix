{
  flake.nixosModules.kubernetes = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [k3s];
    services.k3s.enable = true;
    services.k3s.configPath = pkgs.toYAMLFile {
      disable = ["traefik"];
      disable-helm-controller = true;
    };
  };
}
