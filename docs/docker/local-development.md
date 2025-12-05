# 🐳 Docker — Local Development & Build Guide
_A standardized template for JVM-based backend services_

This template provides a consistent, production-aligned workflow for containerizing JVM applications (Java / Kotlin / Clojure).  
It is framework-agnostic and designed to be reused across backend services.

---

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [First-Time Build & Run](#first-time-build--run)
4. [Rebuild Workflow](#rebuild-workflow)
5. [One-Command Rebuild Script](#one-command-rebuild-script)
6. [Useful Docker Commands](#useful-docker-commands)
7. [Publishing to Docker Hub](#publishing-to-docker-hub)
8. [Recommended Project Structure](#recommended-project-structure)
9. [Multi-Stage Dockerfile Template](#multi-stage-dockerfile-template)
10. [Optional docker-compose Template](#optional-docker-compose-template)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)
13. [How to Reuse This Template](#how-to-reuse-this-template)
14. [CI/CD: GitHub Actions Workflow](#cicd-github-actions-workflow)

---

# Overview

A Docker-based workflow provides:

- Consistent local and production environments
- Fast onboarding for new developers
- Predictable builds and dependency isolation
- Smooth CI/CD integration
- Infrastructure parity between multiple backend services

This repository serves as a **template for engineering teams**, enabling standardization across JVM microservices.

---

# Prerequisites

Ensure the following tools are installed:

- **Docker** → https://www.docker.com/get-started
- **Gradle** or `./gradlew`
- **JDK 21+** (optional locally if using multi-stage Docker builds)

---

# First-Time Build & Run

### 1) Build the JAR
```bash
./gradlew clean build
```

### 2) Build the Docker image
```bash
docker build -t ${PROJECT_NAME}:latest .
```

### 3) Run the container
```bash
docker run -d -p 8080:8080 --name ${PROJECT_NAME} ${PROJECT_NAME}:latest
```

Service will be available at:

```
http://localhost:8080
```

---

# Rebuild Workflow

When updating code:

### 1) Stop and remove existing container
```bash
docker stop ${PROJECT_NAME}
docker rm ${PROJECT_NAME}
```

### 2) Rebuild the JAR
```bash
./gradlew clean build
```

### 3) Rebuild the Docker image
```bash
docker build -t ${PROJECT_NAME}:latest .
```

### 4) Run the container again
```bash
docker run -d -p 8080:8080 --name ${PROJECT_NAME} ${PROJECT_NAME}:latest
```

---

# One-Command Rebuild Script

```bash
docker stop ${PROJECT_NAME} 2>/dev/null; docker rm ${PROJECT_NAME} 2>/dev/null; ./gradlew clean build && docker build -t ${PROJECT_NAME}:latest . && docker run -d -p 8080:8080 --name ${PROJECT_NAME} ${PROJECT_NAME}:latest
```

---

# Useful Docker Commands

```bash
docker logs ${PROJECT_NAME}
docker logs -f ${PROJECT_NAME}
docker stop ${PROJECT_NAME}
docker start ${PROJECT_NAME}
docker rm ${PROJECT_NAME}
docker rmi ${PROJECT_NAME}:latest
docker ps
docker ps -a
docker images
docker exec -it ${PROJECT_NAME} /bin/bash
```

---

# Publishing to Docker Hub

### 1) Tag the image
```bash
docker tag ${PROJECT_NAME}:latest <DOCKERHUB_USER>/<PROJECT_NAME>:latest
```

### 2) Log in
```bash
docker login
```

### 3) Push to registry
```bash
docker push <DOCKERHUB_USER>/<PROJECT_NAME>:latest
```

### 4) Pull from anywhere
```bash
docker pull <DOCKERHUB_USER>/<PROJECT_NAME>:latest
```

---

# Recommended Project Structure

```
${PROJECT_NAME}/
├── src/main/java
├── src/main/resources
├── Dockerfile
├── docker-compose.yml (optional)
├── .dockerignore
├── build.gradle or pom.xml
└── README.md
```

---

# Multi-Stage Dockerfile Template

```dockerfile
# Stage 1: Build
FROM gradle:8.5-jdk21 AS build
WORKDIR /app
COPY build.gradle settings.gradle ./
COPY gradle ./gradle
COPY src ./src
RUN gradle clean build -x test

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

# Optional docker-compose Template

```yaml
version: '3.8'

services:
  app:
    build: .
    image: ${PROJECT_NAME}:latest
    container_name: ${PROJECT_NAME}
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: docker
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    container_name: ${PROJECT_NAME}-db
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

---

# Troubleshooting

### Container exits immediately
- Check logs: `docker logs ${PROJECT_NAME}`
- Ensure correct port exposure
- Verify JAR exists in `/build/libs`

### Port already in use
```bash
docker run -d -p 8081:8080 ...
```

### Permission issues
On Linux:
```bash
sudo usermod -aG docker $USER
```

### Image size too large
- Multi-stage builds
- `.dockerignore` optimization
- Alpine base images

---

# Best Practices

1. Use `.dockerignore` to reduce build context
2. Prefer multi-stage builds for compact images
3. Use semantic versioning for tags (avoid `latest` in production)
4. Run containers as non-root when possible
5. Use environment variables for configuration
6. Structure Dockerfile for optimal caching
7. Ensure correct application port is exposed

---

# How to Reuse This Template

This repository is designed for reuse across JVM microservices.

### Steps:

1. Clone or click “Use this template”
2. Replace `${PROJECT_NAME}` across:
    - Dockerfile
    - docker-compose
    - scripts
    - GitHub Actions
    - README
3. Set correct ports and environment variables
4. Configure your registry credentials
5. Commit and push — ready for CI/CD

---

# CI/CD: GitHub Actions Workflow

```yaml
name: Build and Publish Docker Image

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Build JAR
        run: ./gradlew clean build -x test

      - name: Docker login
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/${{ github.event.repository.name }}:latest
```
