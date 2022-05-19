##!/bin/bash
CLUSTER_NAME="k8s-gitops-cluster"
REGION=us-east-1
SERVICE_ACCOUNT_NAMESPACE=sealed-secrets
SERVICE_ACCOUNT_NAME=external-secrets
SERVICE_ACCOUNT_IAM_ROLE=EKS-ExteranlSecrets-ServiceAccount-Role
SERVICE_ACCOUNT_IAM_POLICY=EKS-SecretsManager-Policy

#
# Set up the permission policy 
#
cat <<EOF > PermissionPolicy.json
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "ssm:GetParameters"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "kms:Decrypt"
         ],
         "Resource":"*"
      }
   ]
}
EOF

SERVICE_ACCOUNT_IAM_POLICY_ARN=$(aws iam create-policy --policy-name $SERVICE_ACCOUNT_IAM_POLICY \
--policy-document file://PermissionPolicy.json \
--query 'Policy.Arn' --output text)


eksctl utils associate-iam-oidc-provider \
--cluster=$CLUSTER_NAME \
--approve

eksctl create iamserviceaccount \
--cluster=$CLUSTER_NAME \
--region=$REGION \
--name=$SERVICE_ACCOUNT_NAME \
--namespace=$SERVICE_ACCOUNT_NAMESPACE \
--role-name=$SERVICE_ACCOUNT_IAM_ROLE \
--attach-policy-arn=$SERVICE_ACCOUNT_IAM_POLICY_ARN \
--override-existing-serviceaccounts \
--approve

