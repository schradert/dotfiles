{
  description = "System configuration";
  inputs = {
    canivete.url = github:schradert/canivete;

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
    } ({nix, ...}:
      with nix; {
        dotfiles.domain = "trdos.me";
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
          ];
        perSystem = {pkgs, ...}: {
          canivete.pre-commit = {
            languages.shell.enable = true;
            settings = {
              excludes = [".canivete/sops/.+"];
              # TODO extract these tool configurations into options
              hooks.lychee.settings.configPath = toString (pkgs.writers.writeTOML "lychee.toml" {
                exclude_path = ["^\./modules/programs/emacs/config\.org$"];
                # This helm repository doesn't have parent pages
                exclude = ["https://seaweedfs.github.io/seaweedfs/helm"];
              });
              # Used in vim configuration
              hooks.typos.settings.configPath = toString (pkgs.writers.writeTOML "_typos.toml" {default.extend-words.enew = "enew";});
              # zsh not really supported by shfmt
              hooks.shfmt.excludes = ["programs/zsh/.p10k.zsh"];
            };
          };
        };
      });
}
