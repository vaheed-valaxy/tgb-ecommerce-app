
#!/bin/bash

set -euo pipefail

# AWS Configuration
ACCOUNT_ID="254405569649"
REGION="us-east-1"

ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Services to build and push
SERVICES=("product-service" "cart-service" "user-service" "order-service")

# ECR repository prefix
ECR_REPOSITORY_PREFIX="ecommerce-dev"

# ECR login
echo "Logging in to ECR..."

aws ecr get-login-password --region "$REGION" \
  | docker login \
      --username AWS \
      --password-stdin "$ECR_REGISTRY"

# Build, create repository if necessary, tag and push
for SERVICE in "${SERVICES[@]}"; do

  echo ""
  echo "=========================================="
  echo "Processing service: $SERVICE"
  echo "=========================================="

  # Extract repository name
  SERVICE_PUSH="${SERVICE%-service}"

  ECR_REPOSITORY="${ECR_REPOSITORY_PREFIX}/${SERVICE_PUSH}"

  # Check whether ECR repository exists
  echo "Checking ECR repository: $ECR_REPOSITORY"

  if aws ecr describe-repositories \
      --repository-names "$ECR_REPOSITORY" \
      --region "$REGION" >/dev/null 2>&1; then

    echo "Repository already exists: $ECR_REPOSITORY"

  else

    echo "Repository does not exist. Creating..."

    aws ecr create-repository \
      --repository-name "$ECR_REPOSITORY" \
      --region "$REGION" 
      
      # --image-scanning-configuration scanOnPush=true \
      # --image-tag-mutability IMMUTABLE

    echo "Repository created successfully: $ECR_REPOSITORY"

  fi

  # Build Docker image
  echo "Building $SERVICE..."

  docker build -t "ecommerce-dev/$SERVICE:latest" "$SERVICE"

  # Tag Docker image
  echo "Tagging $SERVICE..."

  docker tag \
    "ecommerce-dev/$SERVICE:latest" \
    "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

  # Push Docker image
  echo "Pushing $SERVICE to ECR..."

  docker push "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

  echo "Successfully pushed: $ECR_REPOSITORY:latest"

done

echo ""
echo "=========================================="
echo "All images pushed to ECR successfully!"
echo "=========================================="
