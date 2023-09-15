{ config, lib, pkgs, ... }:
{
  imports = [ ];
  options = {
    etcd.instances = lib.mkOption { default = 3; type = lib.types.int; description = "Number of etcd instances"; };
    etcd.memory = lib.mkOption { default = 512; type = lib.types.int; description = "RAM per instance (MB)"; };
    control-plane.instances = lib.mkOption { default = 3; type = lib.types.int; description = "Number of etcd instances"; };
    control-plane.memory = lib.mkOption { default = 512; type = lib.types.int; description = "RAM per instance (MB)"; };
    worker.instances = lib.mkOption { default = 2; type = lib.types.int; description = "Number of etcd instances"; };
    worker.memory = lib.mkOption { default = 1024; type = lib.types.int; description = "RAM per instance (MB)"; };
    load-balancer.instances = lib.mkOption { default = 2; type = lib.types.int; description = "Number of etcd instances"; };
    load-balancer.memory = lib.mkOption { default = 512; type = lib.types.int; description = "RAM per instance (MB)"; };
  };
  config = {
    terraform.required_providers.libvirt.source = "dmacvicar/libvirt";
    provider.libvirt.uri = "qemu:///system";
    resource = {
      libvirt_network.k8s = {
        name = "k8s";
        domain = "k8s.local";
        autostart = true;
        addresses = [ "10.25.0.0/24" ];
        dns.enabled = true;
        xml.xslt =
          let inherit ((import ../lib/shared.nix { inherit pkgs; }).funcs) templateWithArgs;
          in templateWithArgs ./xslt-dhcp.xml { dhcp_range_start = "10.25.0.1"; dhcp_range_end = "10.25.0.24"; };
      };
    } // (
      let
        inherit (pkgs.lib.attrsets) listToAttrs nameValuePair;
        inherit (pkgs.lib.lists) flatten range;
        instance_nixos = { nixos = "boot"; source = "build/nixos.qcow2"; };
        categories_names = [ "etcd" "control-plane" "worker" "load-balancer" ];
        fmt_volume_name = cat: i: "${cat}_${toString i}_boot";
        fmt_domain_name = cat: i: "${cat}_${toString i}";
        mk_instance_volume = { cat, i, ... }: {
          name = fmt_volume_name cat i;
          base_volume_id = "\${ libvirt_volume.nixos.id }";
        };
        mk_instance_domain = { cat, i }: {
          inherit (config.${cat}) memory;
          name = fmt_domain_name cat i;
          disk.volume_id = "\${ libvirt_volume.${fmt_volume_name cat i}.id }";
          network_interface = { network_id = "\${ libvirt_network.k8s.id }"; wait_for_lease = true; };
        };
        category_range = cat: range 1 config.${cat}.instances;
        category_instances_args = cat: map (i: { inherit cat i; }) (category_range cat);
        instance_args = flatten (map category_instances_args categories_names);
        instances_to_resources = instances: listToAttrs (map (inst: nameValuePair inst.name inst) instances);
      in {
        libvirt_volume = (instances_to_resources (map mk_instance_volume instance_args)) // { nixos = instance_nixos; };
        libvirt_domain = instances_to_resources (map mk_instance_domain instance_args);
      }
    );
  };
}
