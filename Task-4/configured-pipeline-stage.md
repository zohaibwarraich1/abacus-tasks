# Task: Setting up stages in pipeline for build, image build, push, and deploy.

## Pipeline Architecture Overview

- Stage 1 (`build`): Compiles code and verifies dependencies on GitHub Actions runner.
- Stage 2 (`docker-build-push`): Builds Docker image, tags it with Commit SHA & `latest`, and pushes to Amazon ECR.
- Stage 3 (`deploy`): Uses AWS Systems Manager (SSM) to target EC2 instances in Auto Scaling Group and updates container via `docker compose up -d`.

## GitHub Repository Secrets & Environment Setup

1. Go to GitHub Repository Settings -> Secrets and variables -> Actions
2. Add Repository Secret:
    - Name: `ECR_REPOSITORY`
    - Value: `node-app-1`
3. Configure Environment `prod` in GitHub repository settings if using GitHub Environments.
4. **IAM Role Trust Relationship Update for Environments:**
   When defining `environment: prod` in your workflow, GitHub OIDC includes the environment name in the claim. You **must** update the IAM Role's Trust Relationship condition to include:
    ```
    repo:zohaibwarraich1*/simple-react-full-stack*:environment:prod
    ```
   *Note: If this claim is not added to the trust policy, OIDC authorization will always fail.*

## Creating GitHub Actions Workflow

1. Go to GitHub repo and create or update `.github/workflows/ci.yml`.
2. Add the following complete workflow configuration:

```yaml
name: Node.js CI Pipeline

on:
  push:
    branches: [master]
  pull_request: 
    branches: [master]

jobs:
  # Stage 1: Build Application
  build:
    name: Install dependencies and build application
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 26
      
      - name: Install dependencies
        run: npm install

      - name: Build application
        run: npm run build

  # Stage 2: Docker Build and Push to ECR
  docker-build-push:
    name: Build Docker Image and Push to ECR
    needs: build
    runs-on: ubuntu-latest
    environment: prod
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v6.2.3
        with:
          role-to-assume: arn:aws:iam::399894608127:role/github-actions-ssm
          aws-region: ap-south-1

      - name: Log in to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

  # Stage 3: Deploy via SSM to EC2 Instances
  deploy:
    name: Deploy on EC2 via SSM
    needs: docker-build-push
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::399894608127:role/github-actions-ssm
          aws-region: ap-south-1

      - name: Run Deployment via SSM
        run: |
          COMMAND_ID=$(aws ssm send-command \
            --targets "Key=tag:purpose,Values=abacus-task-1" \
            --document-name "AWS-RunShellScript" \
            --parameters '{"commands":["aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 399894608127.dkr.ecr.ap-south-1.amazonaws.com","cd /var/abacus-projects/simple-react-full-stack","docker compose up -d"]}' \
            --query "Command.CommandId" \
            --output text)

          echo "Command ID: $COMMAND_ID"

          # Wait for the command to complete across all targets
          while true; do
            STATUS=$(aws ssm list-commands --command-id "$COMMAND_ID" --query "Commands[0].Status" --output text)
            if [[ "$STATUS" == "Success" || "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]]; then
              break
            fi
            sleep 5
          done

          echo "Overall Status: $STATUS"
          echo "----- OUTPUT -----"
          aws ssm list-command-invocations \
            --command-id "$COMMAND_ID" \
            --details \
            --query "CommandInvocations[*].CommandPlugins[*].Output" \
            --output text

          if [ "$STATUS" != "Success" ]; then
            echo "----- ERROR: Command did not succeed on all instances -----"
            exit 1
          fi
```

## Identity provider, Role and Policy attached to the pipeline

## GitHub Actions Trusted Identity:

- Go to IAM -> Identity providers -> Create provider
- Provider type: OpenID Connect
- Provider URL: https://token.actions.githubusercontent.com
- Audience: sts.amazonaws.com

### GitHub Action IAM Role:

- Go to IAM -> Roles -> Create role
- Select Web Identity
- Select your identity provider i.e https://token.actions.githubusercontent.com
- Audience : sts.amazonaws.com
- Fill GitHub organization, repositery, branch. For more info check [Setup OIDC and Role for GitHub Actions](../Task-3/setup-oidc-for-github-actions.md)
- Select permissions: AmazonSSMFullAccess, AmazonEC2ContainerRegistryFullAccess.
- Ensure the trusted policy as following:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::399894608127:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:zohaibwarraich1*/simple-react-full-stack*:ref:refs/heads/master",
                        "repo:zohaibwarraich1*/simple-react-full-stack*:pull_request",
                        "repo:zohaibwarraich1*/simple-react-full-stack*:environment:prod"
                    ]
                }
            }
        }
    ]
}
```

## Key Configuration Notes

- **OIDC Authentication**: Uses temporary security tokens issued via GitHub OIDC without hardcoding permanent AWS access keys.
- **Auto Scaling Group Support**: `--targets "Key=tag:purpose,Values=abacus-task-1"` dynamically triggers deployment on all running ASG servers simultaneously.
- **Docker Compose Update**: Using `pull_policy: always` inside `docker-compose.yaml` ensures `docker compose up -d` automatically pulls the latest image built in Stage 2.

## Debugging OIDC Authorization Errors with CloudTrail

If OIDC authorization fails during pipeline execution (e.g., `AssumeRoleWithWebIdentity` access denied):

1. Open AWS Console -> **CloudTrail** -> **Event history**.
2. Set Event filter: **Event name** = `AssumeRoleWithWebIdentity`.
3. Open the latest event record to view the exact error details and reason why IAM rejected the request (such as mismatched `sub` claim or unhandled environment string).
