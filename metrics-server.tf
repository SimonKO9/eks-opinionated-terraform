module "metrics_server" {
  source  = "lablabs/eks-metrics-server/aws"
  version = "1.0.0"

  enabled           = true
  argo_enabled      = false
  argo_helm_enabled = false

  helm_release_name = "metrics-server"
  namespace         = "kube-system"

  values = yamlencode({
    "podLabels" : {
      "app" : "metrics-server"
    }
  })

  helm_timeout = 240
  helm_wait    = true
}