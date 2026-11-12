#!/bin/bash

set -e

# ACCOUNT_ID="$1"
# REGION="$2"
# FILTER="$3"

ACCOUNT_ID="254405569649"
REGION="us-east-1"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

SERVICES=("product-service" "cart-service" "user-service" "order-service")

# ECR login
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build, tag and push
for SERVICE in "${SERVICES[@]}"; do
  echo ""
  
  echo "==> Building $SERVICE..."
  docker build -t ecommerce-dev/$SERVICE $SERVICE
  
  SERVICE_PUSH=$(echo $SERVICE | cut -d "-" -f1)
  
  echo "==> Tagging $SERVICE..."
  docker tag ecommerce-dev/$SERVICE:latest $ECR_REGISTRY/ecommerce-dev/$SERVICE_PUSH:latest

  echo "==> Pushing $SERVICE..."
  docker push $ECR_REGISTRY/ecommerce-dev/$SERVICE_PUSH:latest
done

echo ""
echo "Done...All the images pushed to ECR Successfully..!"
