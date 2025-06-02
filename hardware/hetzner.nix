{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) concat fileContents mapAttrsToList mkIf mkMerge pipe;
  in {
    config = mkIf config.platforms.hetzner.enable {
      opentofu.modules = {flake, ...}: {
        config = pipe flake.config.canivete.deploy.nodes [
          (mapAttrsToList (name: _: {
            resource.hcloud_server.${name} = {
              depends_on = ["hcloud_ssh_key.me"];
              inherit name;
              location = "ash";
              # NOTE cpx21 doesn't have enough memory for Windmill...
              server_type = "cpx31";
              image = "debian-12";
              keep_disk = true;
              ssh_keys = ["me"];

              lifecycle.ignore_changes = ["ssh_keys"];
            };
            module."nixos_${name}_system_install".depends_on = ["google_dns_record_set.wildcard-vpn-a" "hcloud_server.${name}"];
          }))
          (concat [
            {
              resource.hcloud_server.${config.root}.public_net.ipv4 = "\${ hcloud_primary_ip.root.id }";
              resource.hcloud_ssh_key.me = {
                name = "me";
                public_key = fileContents (flake.inputs.self + "/${flake.config.canivete.sops.directory}/me.pub");
              };
            }
          ])
          mkMerge
        ];
      };
    };
  };
}
