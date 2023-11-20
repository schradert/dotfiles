final: prev: {
  tmux = prev.tmux.overrideAttrs (_: {
    version = "unstable-2023-04-06";
    src = prev.fetchFromGitHub {
      owner = "tmux";
      repo = "tmux";
      rev = "b9524f5b72d16bd634fc47ad1a4a9d3240bd4370";
      sha256 = "7jvmeMipZcNMqFloMuSgPwKowNqWC1J8/++ha6H/D1M=";
    };
    patches = [];
  });
  tmuxPlugins =
    prev.tmuxPlugins
    // {
      dracula = prev.tmuxPlugins.dracula.overrideAttrs (_: {
        version = "unstable-2023-04-04";
        src = prev.fetchFromGitHub {
          owner = "dracula";
          repo = "tmux";
          rev = "b346d1030696620154309f71d5b14bc657294a98";
          sha256 = "89S8LHTx2gYWj+Ejws5f6YRQgoj0rYE7ITtGtZibl30=";
        };
      });
    };
  # Upgrading sops because: https://github.com/getsops/sops/issues/1263
  # Overriding go modules requires overriding the buildGoModule function instead of attributes directly.
  # Follow the discussion and activity below:
  # [Issue](https://github.com/NixOS/nixpkgs/issues/86349)
  # [PR: buildGoModule](https://github.com/NixOS/nixpkgs/pull/225051)
  # [PR: lib.extendMkDerivation](https://github.com/NixOS/nixpkgs/pull/234651)
  sops = prev.sops.override {
    buildGoModule = args:
      prev.buildGoModule (args
        // rec {
          version = "3.8.1";
          src = prev.fetchFromGitHub {
            owner = "mozilla";
            repo = args.pname;
            rev = "v${version}";
            sha256 = "4K09wLV1+TvYTtvha6YyGhjlhEldWL1eVazNwcEhi3Q=";
          };
          vendorSha256 = "iRgLspYhwSVuL0yarPdjXCKfjK7TGDZeQCOcIYtNvzA=";
        });
  };
  spicetify-cli = prev.spicetify-cli.override {
    buildGoModule = args:
      prev.buildGoModule (args
        // rec {
          version = "2.24.2";
          src = prev.fetchFromGitHub {
            owner = "spicetify";
            repo = args.pname;
            rev = "v${version}";
            sha256 = "jzEtXmlpt6foldLW57ZcpevX8CDc+c8iIynT5nOD9qY=";
          };
          vendorHash = "sha256-rMMTUT7HIgYvxGcqR02VmxOh1ihE6xuIboDsnuOo09g=";
        });
  };
}
