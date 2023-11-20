{spicetify-nix}: [
  (final: prev: {
    spicetify-cli = prev.spicetify-cli.overrideAttrs (_: rec {
      version = "2.24.2";
      src = prev.fetchFromGitHub {
        owner = "spicetify";
        repo = "spicetify-cli";
        rev = "v${version}";
        sha256 = "";
      };
      vendorHash = "";
    });
    spicePkgs = spicetify-nix.packages.${prev.system}.default;
  })
]
