EKS cluster example
===================

# Preinstalled charts/addons

1. AWS LB Controller - automatically provisions NLB for NGINX, which handles SSL termination.
2. ingress-nginx - a popular ingress controller.
3. ExternalDNS - automatically creates an A record for NLB
4. Metrics Server - collects metrics that can be used for autoscaling
5. kube-proxy - a network proxy that runs on each node and load balances traffic
6. CoreDNS - cluster DNS server
7. VPC CNI - AWS native networking for pods

# Quirks and caveats

1. `terraform destroy` will fail unless NLB is manually cleaned first: https://github.com/kubernetes/kubernetes/issues/93390.
An alternative is to abandon AWS LB Controller and provision the NLB with Terraform, which is not a bad thing.
2. NLB is handling SSL termination. In some scenarios one may want to handle SSL in NGINX (ingress-nginx). A cert-manager with TLS-enabled NGINX would be desired here and NLB would simply forward traffic.
3. The A record, added automatically for provisioned NLB, is not automatically removed when cluster is deleted.

# Ideas for improvement

1. Abandon AWS LB Controller. It's more trouble than help when used together with Terraform.
2. Handle SSL termination in NGINX and Kubernetes instead of NLB is definitely more flexible.
3. Manage DNS records in Route 53 using Terraform rather than using External DNS, as things are not cleaned up automatically.
4. Add monitoring module with Prometheus and Grafana, and maybe VictoriaMetrics for metrics long-term persistence.
5. Add a service mesh module, probably [Linkerd2](https://linkerd.io/), as it's very lightweight, improves security and provides observability of cluster communication.