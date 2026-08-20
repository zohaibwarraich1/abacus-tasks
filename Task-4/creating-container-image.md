# Task: Create container images for node-js-app-1 and push it to ECR.

## Creating Dockerfile and Docker Compose

1. Create a `Dockerfile` in the root of the repository:
    ```dockerfile
    # Stage 1: Build stage (Installs devDependencies & compiles bundle with Webpack)
    FROM node:26 AS builder

    WORKDIR /app

    COPY package.json ./

    RUN npm install 

    COPY ./ ./

    RUN npm run build

    # Stage 2: Production runtime stage
    FROM dhi.io/node:26-alpine3.23

    # Set production environment variables
    ENV NODE_ENV=production

    WORKDIR /app

    # Copy production node_modules from builder stage
    COPY --chown=node:node --from=builder /app/node_modules ./node_modules

    # Copy compiled frontend static assets from builder stage
    COPY --chown=node:node --from=builder /app/dist ./dist

    # Copy backend server code from builder stage
    COPY --chown=node:node --from=builder /app/src/server ./src/server

    # Copy package.json for application metadata
    COPY --chown=node:node package.json ./

    USER node

    EXPOSE 8080

    CMD ["node", "src/server/index.js"]
    ```

2. Create a `docker-compose.yaml` in the root of the repository:
    ```yaml
    version: '3.8'
    services:
      web:
        image: 399894608127.dkr.ecr.ap-south-1.amazonaws.com/node-app-1:latest
        container_name: node-app-1
        pull_policy: always
        ports:
          - "8080:8080"
        restart: unless-stopped
        networks:
          - node-app-1-network
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost:8080/"]  
          interval: 30s
          timeout: 7s
          retries: 5
          start_period: 60s
    networks:
      node-app-1-network:
    ```

## Creating ECR Repository in AWS

1. Go to AWS Console -> Amazon ECR
2. Click on Create repository
3. Select Visibility settings: Private ✅
4. Repository name: `node-app-1`
5. Tag immutability: Disabled
6. Encryption configuration: AES-256 ✅
7. Click on Create repository

## Build and Push Image Manually (Optional Testing)

1. Authenticate Docker with Amazon ECR:
    ```bash
    aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 399894608127.dkr.ecr.ap-south-1.amazonaws.com
    ```

2. Build the Docker image:
    ```bash
    docker build -t 399894608127.dkr.ecr.ap-south-1.amazonaws.com/node-app-1:latest .
    ```

3. Push the image to Amazon ECR:
    ```bash
    docker push 399894608127.dkr.ecr.ap-south-1.amazonaws.com/node-app-1:latest
    ```
