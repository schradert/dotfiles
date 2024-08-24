
{
  # NOTE https://github.com/All-Hands-AI/OpenHands
  # NOTE https://docs.all-hands.dev/modules/usage/how-to/openshift-example
  # TODO follow this project closer for a better kubernetes setup without DinD
  # perSystem.dotfiles.helm.openhands = {
  #   namespace = "ai";
  #   resources.persistentVolumeClaims = {
  #     openhands-workspace.spec.accessModes = ["ReadWriteOnce"];
  #     openhands-workspace.spec.resources.requests.storage = "1Gi";
  #     openhands-docker.spec.accessModes = ["ReadWriteOnce"];
  #     openhands-docker.spec.resources.requests.storage = "1Gi";
  #   };
  #   values = {
  #     # TODO persistence
  #     # persistence = {};
  #   };
  # };
}
