{
  perSystem.canivete.kubenix.helm.snapshot-controller = {
    namespace = "kube-system";
    chart = {
      repo = "https://piraeus.io/helm-charts";
      chart = "snapshot-controller";
      version = "3.0.5";
      sha256 = "vEdvr5sz5C8jOL4CgteS78Tg48R2k81rrnWK6KnzDSE=";
    };
    values.controller.serviceMonitor.create = true;
    values.webhook.enabled = false;
  };
}
