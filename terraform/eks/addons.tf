# metrics-server: required for the Horizontal Pod Autoscaler to read CPU/memory.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [module.eks]
}

# Application namespace, created here so it is covered by the "app" Fargate
# profile before any workload manifests are applied.
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/part-of" = var.project
    }
  }

  depends_on = [module.eks]
}
