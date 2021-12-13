#
# Bootstrapping the cluster with Flux
#
export CLUSTER_NAME=k8s-addon-cluster
export GITHUB_TOKEN=817e48f922cf95b645c188ea9c7c7e0ecc417a1f
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
# Create a Kustomization resource under 'cluster/$CLUSTER_NAME' that points to the 'crossplane' directory 
# Pushing this file to the Git repository will trigger a Flux reconcilliation loop which will install Crossplane core components and Crossplane AWS provider-specific components
#
mkdir -p ./clusters/${CLUSTER_NAME}
flux create kustomization local-source \
  --source=flux-system \
  --namespace=flux-system \
  --path=./crossplane \
  --prune=true \
  --validation=client \
  --interval=30s \
  --export > ./clusters/$CLUSTER_NAME/crossplane.yaml

#
# Create a Kustomization resource under 'cluster/$CLUSTER_NAME' that points to the 'crossplane' directory 
# Pushing this file to the Git repository will trigger a Flux reconcilliation loop which will install Crossplane core components and Crossplane AWS provider-specific components
#
mkdir -p ./clusters/${CLUSTER_NAME}
flux create kustomization local-source \
  --source=flux-system \
  --namespace=flux-system \
  --path=./applications \
  --prune=true \
  --validation=client \
  --interval=30s \
  --export > ./clusters/$CLUSTER_NAME/applications.yaml