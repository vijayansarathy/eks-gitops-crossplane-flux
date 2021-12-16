#
# Bootstrapping the cluster with Flux
# The bootstrap process will automatically create a GitRepository custom resource that points to the given repository
# The GitRepository resource is named after the namespace where Flux GitOps ToolKit is installed. In this case, it is 'flux-system'
#
export CLUSTER_NAME=k8s-addon-cluster
export GITHUB_TOKEN=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
export GITHUB_USER=vijayansarathy
kubectl create ns flux-system
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --namespace=flux-system \
  --repository=eks-gitops-crossplane-flux \
  --branch=main \
  --path=clusters/$CLUSTER_NAME \
  --personal

#
# Create a Kustomization resource under 'cluster/$CLUSTER_NAME' that points to the 'crossplane' directory in the config repo.
# Pushing this file to the Git repository will trigger a Flux reconcilliation loop which will install the following:
# 1. Crossplane core components 
# 2. Crossplane AWS provider-specific components
# 3. Crossplane Configuration package for creating EKS cluster and other AWS resources
# 4. Composite resource to create an EKS cluster
# When this reconcilliation loop is completed, Crossplane will start provisioning the EKS cluster.
# It will take about 10 minutes for the cluster to be ready and operational
#
mkdir -p ./clusters/${CLUSTER_NAME}
flux create kustomization crossplane \
  --source=flux-system \
  --namespace=flux-system \
  --path=./crossplane \
  --prune=true \
  --validation=client \
  --interval=30s \
  --export > ./clusters/$CLUSTER_NAME/crossplane.yaml

#
# To deploy workloads to the remote cluster using the credentials of the cluster creator, continue with the following step.
# To deploy using the credentials of a service account with appropriate set of RBAC permissions, refer to ./remote/remote-cluster-setup.sh before proceeding further.
# Create a Kustomization resource under 'cluster/$CLUSTER_NAME' that points to the 'applications' directory 
# Pushing this file to the Git repository will trigger a Flux reconcilliation loop which will install the following:
# 1. Sample web application that exposes Prometheus metrics
# 2. Prometheus server which scrapes the metrics from the sample application and sends it to an AMP workspace
#
mkdir -p ./clusters/${CLUSTER_NAME}
flux create kustomization applications \
  --source=flux-system \
  --namespace=flux-system \
  --path=./applications \
  --prune=true \
  --validation=client \
  --interval=30s \
  --export > ./clusters/$CLUSTER_NAME/applications.yaml