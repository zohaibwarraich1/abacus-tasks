# Task: Creating OIDC Provider for Github actions to execute pipeline using SSM.

## Creating OIDC Provider 

1. Go to IAM Dashboard
2. Click on Identity Providers
3. Click on Add Provider
4. Select OpenID Connect
5. Enter the URL of the OpenID Connect provider
    ```yaml
    https://token.actions.githubusercontent.com
    ```
6. For Audience, enter `sts.amazonaws.com`.
7. Click on Add Provider

## Creating IAM Role for SSM

1. Create role in IAM
2. Select Trusted Entity as Web identity
3. Select the identity provider created recently
4. Select audience as sts.amazonaws.com
5. Enter Github organzation/username and dont forgert to put * at the end. **Example:**
    ```yaml
    <github-organization>*
    ```
6. Add Github repo name only and dont forgert to put * at the end. **Example:**
    ```yaml
    <github-repo-name>*
    ```
7. Add repo branch that is mentioned in workflow.yaml for execution. **Example:**
    ```yaml
    <branch-name>
    ```
8. Finally combined value will be like:
    ```yaml
    repo:<github-organization>*/<github-repo-name>*:ref:refs/heads/<branch-name>
    ```
9. Click on Next
10. Add appropiate permissions to the role. Moreover, must add the following policy for Github Actions to access EC2 via SSM during pipeline execution:
    ```yaml
    arn:aws:iam::aws:policy/AmazonSSMFullAccess
    ```
11. Click on Next
12. Click on Create Role

## Attach the IAM Role to EC2 Instance which must be containing policy -> AmazonSSMManagedInstanceCore

## Creating Github Actions Workflow

1. Go to github repo where workflow.yaml will be placed
2. Must add following in the **Permissions** section of job in workflow.yaml:
    ```yaml
    permissions:
      id-token: write
      contents: read
    ```
3. Now, in the same workflow.yaml file, add the following steps in the **job** section:
    ```yaml
    jobs:
      <job-name>:
        runs-on: <runner-name>
        permissions:
          id-token: write
          contents: read
        steps:
          - name: Configure AWS Credentials
            uses: aws-actions/configure-aws-credentials@v4
            with:
              role-to-assume: <IAM-role-name-recently-created>
              aws-region: <AWS-region-name>

        # continue...
    ```