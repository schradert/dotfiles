{
  canivete.deploy.nixos.modules.pxe = {config, flake, lib, pkgs, ...}: with lib; let
    inherit (flake.config.canivete.people) me;
    inherit (config.dotfiles) pxe;
    base = flake.inputs.nixpkgs.lib.nixosSystem {
      inherit (pkgs) system;
      modules = toList ({modulesPath, ...}: {
        imports = [(modulesPath + "/installer/netboot/netboot-niminal.nix")];
        services.openssh = {
          enable = true;
          openFirewall = true;
          settings.PasswordAuthentication = false;
          settings.KbdInteractiveAuthentication = false;
        };
        users.users.root.openssh.authorizedKeys.keyFiles = [(flake.inputs.self + "/.canivete/sops/${me}.pub")];
      });
    };
  in {
    # TODO figure out running this on a vpn cloud machine
    # TODO convert this to systemd-boot before attempting (or maybe I should use GRUB?)
    options.dotfiles.pxe = {
      server = mkEnableOption "PXE server";
      client = mkEnableOption "Netboot with chainloaded iPXE";
    };
    config = mkMerge [
      (mkIf pxe.server {
        services.pixiecore = {
          enable = true;
          openFirewall = true;
          dhcpNoBind = true;
          mode = "boot";
          kernel = "${base.kernel}/bzImage";
          initrd = "${base.netbootRamdisk}/initrd";
          cmdLine = "init=${base.toplevel}/init loglevel=4";
          debug = true;
        };
      })
      (mkIf pxe.client {
        environment.shellAliases.reboot2PXE = "${pkgs.grub2}/bin/grub-editenv /boot/grub/grubenv set entry=ipxe && reboot";
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          extraFiles."ipxe.efi" = "${pkgs.ipxe}/ipxe.efi";
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
