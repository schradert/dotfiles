{
  dotfiles = {
    config,
    inputs,
    lib,
    ...
  }: let
    inherit (lib) concat fileContents mapAttrsToList mkIf pipe;
  in {
    config = mkIf config.platforms.google.enable {
      opentofu.modules = {flake, ...}: let
        inherit (flake.config.canivete) deploy sops;
      in {
        config = pipe deploy.nodes [
          (mapAttrsToList (name: node: {
            resource.google_compute_instance.${name} = {
              # TODO what scopes will I need to set?
              inherit name;
              machine_type = "e2-standard-4";
              allow_stopping_for_update = true;
              boot_disk.initialize_params = {
                type = "pd-balanced";
                size = 200;
                image = "debian-12";
              };
              metadata_startup_script = "sed -i 's/PermitRootLogin no/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config";
              metadata.ssh-keys = "root:${fileContents (inputs.self + "/${sops.directory}/me.pub")} root";
              service_account.email = "\${ google_service_account.compute.email }";
              service_account.scopes = ["cloud-platform"];

              inherit (node) hostname;
              network_interface.subnetwork = "\${ google_compute_subnetwork.main.name }";
              can_ip_forward = true;
            };
            module."nixos_${name}_system_install".depends_on = ["google_dns_record_set.wildcard-vpn-a" "google_compute_instance.${name}"];
          }))
          (concat [
            {
              resource.google_compute_instance.${config.root}.network_interface.access_config.nat_ip = "\${ google_compute_address.root.address }";
              resource.google_compute_firewall.root.destination_ranges = ["\${ google_compute_instance.${config.root}.network_interface.0.network_ip }"];
            }
          ])
        ];
      };
    };
  };
}
