{
  config,
  inputs,
  nix,
  ...
}:
with nix; {
  perSystem.canivete.opentofu.workspaces.cloud = {
    plugins = ["integrations/github" "gitlabhq/gitlab"];
    modules.default = {
      provider.github.token = vals.sops "default.yaml#/github_pat";
      resource.github_user_ssh_key = pipe config.canivete.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
      provider.gitlab.token = vals.sops "default.yaml#/gitlab_pat";
      resource.gitlab_user_sshkey = pipe config.canivete.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = readFile (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
    };
  };
}
