#
# In order for Flux V2 to use private Git repositories as a source, we will have to provide a SSH key
# When creating a source for a private Git repository that requires SSH authentication, Flux will generate an SSH key and emit the public key to the output
# Flux will create a secret with the private key in the given namespace based on the name given to the 'flux create secret git' command
# The name of this secret should match with the name specified for the GitRepository resource that points to the corresponding Git repository.
# This public key emitted to the output should be added to the Git repository to enable Flux connect to the private repository.
#
flux create secret git flux-remote-bootstrap \
--url=ssh://git@github.com/vijayansarathy/eks-gitops-crossplane-flux \
--namespace=flux-system \
--ssh-key-algorithm=ecdsa \
--ssh-ecdsa-curve=p521 \
--export > flux-remote-bootstrap.yaml


#
# For bootstrapping Flux on a remote workload cluster using Flux on a management cluster, the above Secret 'flux-remote-bootstrap' has to be created on the workload cluster.
# This will allow the workload cluster to be able to sync to the Git repo specified in the above CLI command.
# In order for this to work, the public key from the above public-private key pair should have been added to that repo
# Second, as we are using Flux to deploy Flux, the above Secret has to be sync'd to the workload cluster using GitOps workflow
# This entails storing this Secret in Git which is not safe.
# So, we have to seal this Secret using Sealed Secrets and convert it to a SealedSecret resource before storing it in Git.
# The sealing keys themselves are stored in AWS Secrets Manahger
# The Secret 'flux-remote-bootstrap' can be sealed using the 'kubeseal' CLI with the public key portion (certificate) of the sealing keys
#

#
# First generate the sealing keys which is just public-private key pair generated using OpenSSL
# The sealing keys will have to stored in AWS Secrets Manager
# They will be retrieved from Secrets Manager by External Secrets Controller and will be deployed as a Kubernetes Secret 
#
export PRIVATE_KEY="sealed-secrets-sealing-key"
export PUBLIC_KEY="sealed-secrets-sealing-crt"
export NAMESPACE="sealed-secrets"
export SECRET_NAME="sarathy-sealing-keys"
export SECRET_FILE="sarathy-sealing-keys.yaml"
openssl req -x509 -nodes -newkey rsa:4096 -keyout "$PRIVATE_KEY" -out "$PUBLIC_KEY" -subj "/CN=sealed-secret/O=sealed-secret"

#
# The Kubernetes Secret generated from the sealing keys using External Secrets Controller will look like the one generated with these commands
#
kubectl create ns "$NAMESPACE"
kubectl -n "$NAMESPACE" create secret tls "$SECRET_NAME" --cert="$PUBLIC_KEY" --key="$PRIVATE_KEY"
kubectl -n "$NAMESPACE" label secret "$SECRET_NAME" sealedsecrets.bitnami.com/sealed-secrets-key=active
kubectl -n "$NAMESPACE" get Secret "$SECRET_NAME" -o yaml > "$SECRET_FILE"


#
# Now, seal the 'flux-remote-bootstrap' Secret using the 'kubeseal' CLI with the public key portion (certificate) of the sealing keys
# Finally, commit the sealed secret file 'flux-bootstrap-sealed-secret.yaml' to a Git repo
#
kubeseal --cert "$PUBLIC_KEY" --format yaml < flux-remote-bootstrap.yaml > flux-bootstrap-sealed-secret.yaml










