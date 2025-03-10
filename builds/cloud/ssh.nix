{
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) pipe filterAttrs hasAttrByPath mapAttrs fileContents;
in {
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["integrations/github" "gitlabhq/gitlab"];
    modules.default = {
      provider.github.token = canivete.vals.sops "default.yaml#/github_pat";
      resource.github_user_ssh_key = pipe config.canivete.meta.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "github"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = fileContents (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
      provider.gitlab.token = canivete.vals.sops "default.yaml#/gitlab_pat";
      resource.gitlab_user_sshkey = pipe config.canivete.meta.people.users [
        (filterAttrs (_: hasAttrByPath ["accounts" "gitlab"]))
        (mapAttrs (name: _: {
          title = "dotfiles";
          key = fileContents (inputs.self + "/.canivete/sops/${name}.pub");
        }))
      ];
    };
  };
}
