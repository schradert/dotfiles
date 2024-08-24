{
  description = "System configuration";
  inputs = {
    canivete.url = github:schradert/canivete;
    # 2024/08/14 broken mealie build
    # canivete.inputs.nixpkgs.url = github:nixos/nixpkgs/b73c2221a46c13557b1b3be9c2070cc42cf01eb3;
    # 2024/08/15 broken delta build
    # canivete.inputs.nixpkgs.url = github:nixos/nixpkgs/195662d20d9c35f988d0122d34479f90da709e0;
    # 2024/08/16 broken wezterm build
    canivete.inputs.nixpkgs.url = github:nixos/nixpkgs/e57228512561add2e46812f3e61a7304b46a7958;

    # TODO keep tabs on this project to see if it's evolving enough to try to use
    # NOTE nix-doom-emacs marked as broken for now so we use overlay
    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "canivete/nixpkgs";
    emacs-overlay.url = github:nix-community/emacs-overlay;
    emacs-overlay.inputs.nixpkgs.follows = "canivete/nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    # Secret management in Nix deployments
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "canivete/nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "canivete/nixpkgs-stable";

    # Authenticate with GKE clusters using kubectl
    gke-gcloud-auth-plugin-flake.url = github:christian-blades-cb/gke-gcloud-auth-plugin-nix;

    # Spotify ecosystem
    spicetify-nix.url = github:Gerg-L/spicetify-nix;
    spicetify-nix.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # NixOS on steamdeck
    jovian.url = github:Jovian-Experiments/Jovian-NixOS;
    jovian.inputs.nixpkgs.follows = "canivete/nixpkgs";

    # Docker images
    nix2container.url = github:nlewo/nix2container;
    nix2container.inputs.nixpkgs.follows = "canivete/nixpkgs";
  };
  outputs = inputs:
    inputs.canivete.lib.mkFlake {
      inherit inputs;
      everything = [./modules ./builds];
    } ({
      config,
      nix,
      ...
    }:
      with nix; {
        dotfiles.domain = "trdos.me";
        canivete.root = "sirver";
        canivete.people = {
          me = "tristan";
          users.tristan = {
            name = "Tristan Schrader";
            accounts.github = "schradert";
            accounts.gitlab = "schrader.tristan";
            profiles.default.email = "t0rdos@pm.me";
            profiles.work.email = "tristan@climaxfoods.com";
          };
        };
        canivete.pkgs.config.allowUnfreePredicate = pkg:
          elem (getName pkg) [
            "android-studio-stable"
            "discord"
            "raycast"
            "slack"
            "spotify"
            "beeper"
            "steam-run"
            "steam-jupiter-original"
            "steam"
            "steamdeck-hw-theme"
            # Sabnzbd only supports unrar currently, but unar is a better alternative to keep track of
            # NOTE https://github.com/sabnzbd/sabnzbd/issues/1120
            "unrar"
          ];
        perSystem = {
          config,
          pkgs,
          ...
        }: {
          packages.default = pkgs.wrapFlags config.packages.opentofu "--add-flags \"deploy\"";
          canivete.pre-commit.languages.shell.enable = true;
          canivete.pre-commit.settings = {
            excludes = [".canivete/sops/.+"];
            # TODO extract these tool configurations into options
            hooks.lychee.settings.configPath = toString (pkgs.writers.writeTOML "lychee.toml" {
              exclude_path = ["^\./modules/programs/emacs/config\.org$"];
              exclude = [
                # These helm repositories don't have parent pages
                "https://seaweedfs.github.io/seaweedfs/helm"
                "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
                "https://charts.rook.io/release"
                "https://kubernetes-sigs.github.io/descheduler"
                "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
                "https://k8tz.github.io/k8tz"
                "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
                "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui"
                "https://gitlab.com/api/v4/projects/43892189/packages/helm/stable"
                # Cluster local addresses
                "svc.cluster.local"
                # URLs built with substitution
                "^.+\${.+}.+$"
              ];
            });
            # Used in vim configuration
            hooks.typos.settings.configPath = toString (pkgs.writers.writeTOML "_typos.toml" {default.extend-words.enew = "enew";});
            # zsh not really supported by shfmt
            hooks.shfmt.excludes = ["programs/zsh/.p10k.zsh"];
          };
        };
        flake.dotfiles = mapAttrs (_: getAttr "dotfiles") config.allSystems;
      });
}
