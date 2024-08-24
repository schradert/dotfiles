{
  perSystem.canivete.kubenix.clusters.prod.modules.excalidraw = {helm, ...}: {
    kubernetes.helm.releases.excalidraw = {
      chart = helm.fetch {
        repo = "https://gitlab.com/api/v4/projects/43892189/packages/helm/stable";
        chart = "excalidraw";
        version = "0.1.4";
        sha256 = "mFTSDKfYfGujNizrKao7PdsHYsKuDd81lrDb/BBRcAQ=";
      };
    };
  };
}
