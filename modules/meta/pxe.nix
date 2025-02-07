{
  canivete.deploy.nixos.modules.pxe = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.pxe) client server;
    inherit (flake.config.canivete.people) me;
    inherit (flake.inputs) nixpkgs self;
    inherit (lib) toList mkIf mkMerge mkEnableOption;
    inherit (pkgs) ipxe grub2 system;
    inherit
      (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = toList ({modulesPath, ...}: {
          imports = [(modulesPath + "/installer/netboot/netboot-niminal.nix")];
          services.openssh = {
            enable = true;
            openFirewall = true;
            settings.PasswordAuthentication = false;
            settings.KbdInteractiveAuthentication = false;
          };
          users.users.root.openssh.authorizedKeys.keyFiles = [(self + "/.canivete/sops/${me}.pub")];
        });
      })
      kernel
      netbootRamdisk
      toplevel
      ;
  in {
    # TODO figure out running this on a vpn cloud machine
    # TODO convert this to systemd-boot before attempting (or maybe I should use GRUB?)
    options.dotfiles.pxe = {
      server = mkEnableOption "PXE server";
      client = mkEnableOption "Netboot with chainloaded iPXE";
    };
    config = mkMerge [
      (mkIf server {
        services.pixiecore = {
          enable = true;
          openFirewall = true;
          dhcpNoBind = true;
          mode = "boot";
          kernel = "${kernel}/bzImage";
          initrd = "${netbootRamdisk}/initrd";
          cmdLine = "init=${toplevel}/init loglevel=4";
          debug = true;
        };
      })
      (mkIf client {
        environment.shellAliases.reboot2PXE = "${grub2}/bin/grub-editenv /boot/grub/grubenv set entry=ipxe && reboot";
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          extraFiles."ipxe.efi" = "${ipxe}/ipxe.efi";
          extraConfig = ''
            if [ "''${entry}" = "ipxe" ]; then
              set entry=""
              save_env --file /grub/grubenv entry
              menuentry "Reinstall via iPXE" {
                chainloader /ipxe.efi
              }
            fi
          '';
        };
      })
    ];
  };
}
