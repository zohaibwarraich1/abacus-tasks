## Task: Create CodeBuild for node-js-app-1.

### Project configuration:

1. Go to AWS Console -> AWS CodeBuild
2. Click on "Create build project"
3. In the project configuration section, enter the project name as **node-js-app-1-build-project** 
4. Select Project type as default.

### Source:

1. Add source as Github or where you repositery resides.
2. Select the repositery. 


### Primary source webhook events:

1. Check the Webhook box
2. Build type set to Single
3. Comment approval set to "ALL_PULL_REQUESTS" and Approval roles are GITHUB_WRITE, GITHUB_MAINTAIN, GITHUB_ADMIN
4. In additional configuration, Select Event type as Push and PULL_REQUEST_MERGED
5. In filters, set condition to start the build when event is performed on specific branches.

### Environment:

> Note: Specify the environment on which the AWS will execute your CI pipeline. 

1. Provisioning model set to On-demand.
2. Environment image set to managed image. 
3. Compute is EC2
4. Running mode is Container
5. Operating system is Ubuntu
6. Runtime is standard
7. Select the image and image version according to requirement.
8. Select a role if existing already, otherwise create a new one.
9. In Additional configuration, scroll down and check the box of **privilieged** to give permission of **accessing docker daemon socket** during pipeline execution.

### Buildspec:

1. Use a builspec file if you have in your repo (by default, it searches in the root directory of repo.)
2. If you don't have a builspec file, you can create one by clicking on **Insert build commands**.
```yaml
version: 0.2

run-as: root

env:
  variables: 
    PORT: "8000"
  parameter-store:
    ECR_REGISTRY: /nodeApp1/ecr/registry
    ECR_REPOSITORY: /nodeApp1/ecr/repositery
  # exported tags are used to pass variable for future pipeline stages e.g CodeDeploy.
  exported-variables:
    - IMAGE_TAG
  secrets-manager:
    DOCKER_USERNAME: dockerhub/creds:username
    DOCKER_PASSWORD: dockerhub/creds:password

phases:
  install:
    run-as: root
    on-failure: ABORT
    runtime-versions:
      nodejs: 26
    commands:
      - echo "Installing dependencies..."
      - npm install
      - echo "Dependencies installed successfully..."

  pre_build:
    run-as: root
    on-failure: ABORT
    commands:
      - echo "Logging in to Docker Hub..."
      - echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
      - echo "Login to Docker Hub completed..."
      - echo "Logging in to Amazon ECR..."
      - aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
      - echo "Login to ECR completed..."
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - echo "Image Tag is set to $IMAGE_TAG"

  build:
    run-as: root
    on-failure: ABORT
    commands:
      - echo "Building the application..."
      - npm run build
      - echo "Application Build completed..."
      - echo "Building the Docker image..."
      - docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
      - echo "Docker image build completed..."

  post_build:
    run-as: root
    on-failure: ABORT
    commands:
      - echo "Pushing the Docker image..."
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      - echo "Docker image push completed..."
```

## IAM Role and Policy

### AWS CodeBuild Service Role:-

1. Go to IAM Console -> Roles.
2. Select the role that was created through the CodeBuild i.e **codebuild-node-js-app-1-build-project-service-role**. 
3. Go to permission tab and assign the following policies to the role:
  * EC2InstanceProfileForImageBuilderECRContainerBuilds
  ```yaml
  # For allowing CodeBuild to access ECR registry to push images.
  ```
  * CodeBuildBasePolicy-node-js-app-1-build-project-ap-south-1
  ```json
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Resource": [
                  "arn:aws:logs:ap-south-1:399894608127:log-group:/aws/codebuild/node-js-app-1-build-project",
                  "arn:aws:logs:ap-south-1:399894608127:log-group:/aws/codebuild/node-js-app-1-build-project:*"
              ],
              "Action": [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents"
              ]
          },
          {
              "Effect": "Allow",
              "Resource": [
                  "arn:aws:s3:::codepipeline-ap-south-1-*"
              ],
              "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:GetObjectVersion",
                  "s3:GetBucketAcl",
                  "s3:GetBucketLocation"
              ]
          },
          {
              "Effect": "Allow",
              "Action": [
                  "codebuild:CreateReportGroup",
                  "codebuild:CreateReport",
                  "codebuild:UpdateReport",
                  "codebuild:BatchPutTestCases",
                  "codebuild:BatchPutCodeCoverages"
              ],
              "Resource": [
                  "arn:aws:codebuild:ap-south-1:399894608127:report-group/node-js-app-1-build-project-*"
              ]
          },
          {
              "Sid": "Statement1",
              "Effect": "Allow",
              "Action": [
                  "ssm:GetParameter",
                  "ssm:GetParameters"
              ],
              "Resource": [
                  "arn:aws:ssm:ap-south-1:399894608127:parameter/nodeApp1/ecr/registry",
                  "arn:aws:ssm:ap-south-1:399894608127:parameter/nodeApp1/ecr/repositery"
              ]
          },
          {
              "Sid": "Statement2",
              "Effect": "Allow",
              "Action": [
                  "secretsmanager:GetSecretValue",
                  "secretsmanager:ListSecrets"
              ],
              "Resource": [
                  "arn:aws:secretsmanager:ap-south-1:399894608127:secret:dockerhub/creds-*"
              ]
          }
      ]
    }
  ```

### Create secrets in AWS Secrets Manager for Docker Hub credentials:

1. Go to AWS Console -> AWS Secrets Manager
2. Click on "Store a new secret"
3. Select "Other type of secrets" (if not found)
4. Select "Plaintext" as the secret type
5. Enter the Docker Hub username and password in a single secret.
6. Click on "Next"
7. Click on "Next"
8. Enter the secret name as "dockerhub/creds"
9. Click on "Next"
10. Click on "Create secret"  
11. Then add them in pipeline in following manner:
    ```yaml
    env:
      secrets-manager:
        DOCKER_USERNAME: dockerhub/creds:username
        DOCKER_PASSWORD: dockerhub/creds:password
    ```
### Create parameters in AWS Systems Manager for Docker Hub credentials:

1. Go to AWS Console -> AWS Systems Manager
2. Click on "Parameters"
3. Click on "Create parameter"
4. Enter the parameter name as "/nodeApp1/ecr/registry"
5. Enter the parameter type as "String" and keep it secret.
6. Enter the parameter value as "your ecr registry"
7. Click on "Create parameter"
8. Again click on "Create parameter"
9. Enter the parameter name as "/nodeApp1/ecr/repositery"
10. Enter the parameter type as "String" and keep it secret.
11. Enter the parameter value as "your ecr repository" 
12. Click on "Create parameter"
13. Then add them in pipeline in following manner:
    ```yaml
    env:
      parameter-store:
        ECR_REGISTRY: /nodeApp1/ecr/registry
        ECR_REPOSITORY: /nodeApp1/ecr/repositery
    ```

> **Note**: Do not set the same environment variable in both secrets manager and parameter store

### Next, Creating CodePipeline:
<!-- 
1. Go to AWS Console -> AWS CodePipeline
2. Click on "Create pipeline"
3. In the **project configuration section**, enter the project name as **node-js-app-1-pipeline** and select **Linux** as the operating system. (for more info on codepipeline configuration see [codepipeline-configuration.md](codepipeline-configuration.md)) -->

