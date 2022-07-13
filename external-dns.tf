module "external_dns_helm" {
  source  = "lablabs/eks-external-dns/aws"
  version = "1.1.0"

  enabled           = true
  argo_enabled      = false
  argo_helm_enabled = false

  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  helm_release_name = "aws-ext-dns-helm"
  namespace         = "aws-external-dns-helm"

  values = yamlencode({
    "LogLevel" : "debug"
    "provider" : "aws"
    "registry" : "txt"
    "txtOwnerId" : "eks-cluster"
    "txtPrefix" : "external-dns"
    "policy" : "sync"
    "domainFilters" : [
      "simonko.xyz",
    ]
    "publishInternalServices" : "true"
    "triggerLoopOnEvent" : "true"
    "interval" : "5s"
    "podLabels" : {
      "app" : "aws-external-dns-helm"
    }
  })

  helm_timeout = 240
  helm_wait    = true
}