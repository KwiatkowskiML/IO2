# Resellio - The Modern Ticket Marketplace

Resellio is a full-stack, cloud-native ticketing marketplace platform built with a microservices architecture. It features a robust backend with FastAPI, a reactive Flutter frontend, and is fully deployable on AWS using Terraform.

[![API Tests](https://github.com/KwiatkowskiML/IO2/actions/workflows/tests.yml/badge.svg)](https://github.com/KwiatkowskiML/IO2/actions/workflows/tests.yml)

## Table of Contents

- [Core Features](#core-features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started (Local Development)](#getting-started-local-development)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Running Automated Tests](#running-automated-tests)
- [AWS Deployment (Terraform)](#aws-deployment-terraform)
  - [Prerequisites](#prerequisites)
  - [Step 1: Bootstrap Terraform Backend](#step-1-bootstrap-terraform-backend)
  - [Step 2: Build and Push Docker Images](#step-2-build-and-push-docker-images)
  - [Step 3: Deploy Main Infrastructure](#step-3-deploy-main-infrastructure)
  - [Resetting the Database](#resetting-the-database)
- [CI/CD Pipeline](#cicd-pipeline)

## Core Features

### Backend & API
- **Microservices Architecture**: Two main services for ```Authentication``` and ```Events/Ticketing```.
- **RESTful API**: Clean, well-defined API endpoints powered by FastAPI.
- **Role-Based Access Control (RBAC)**: Distinct roles for ```Customer```, ```Organizer```, and ```Administrator```.
- **JWT Authentication**: Secure, token-based authentication.
- **Admin Verification**: Organizers must be verified by an administrator before they can create events.
- **Event & Ticket Management**: Organizers can create events and define ticket types.
- **Shopping Cart**: Customers can add tickets to a cart and proceed to checkout.
- **Ticket Resale Marketplace**: Users can list their purchased tickets for resale and other users can buy them.

### Frontend
- **Cross-Platform**: A single codebase for mobile and web, built with Flutter.
- **Reactive UI**: State management with BLoC/Cubit for a responsive and predictable user experience.
- **Role-Specific Dashboards**: Tailored user interfaces for Customers, Organizers, and Administrators.
- **Adaptive Layout**: Responsive design that works on both mobile and desktop screens.
- **Secure Routing**: ```go_router``` protects routes based on authentication status.

### Infrastructure & DevOps
- **Infrastructure as Code (IaC)**: Fully automated AWS deployment using Terraform.
- **Containerized Services**: All backend services are containerized with Docker for consistency.
- **Local Development Environment**: Simplified local setup using ```docker-compose```.
- **CI/CD Automation**: Automated testing pipeline with GitHub Actions.
- **Cloud-Native Deployment**: Leverages AWS ECS Fargate, Aurora Serverless, ALB, and Secrets Manager.

## Architecture

The project is designed with a clear separation of concerns, both in its local and cloud deployments.

```mermaid
graph TD
    subgraph "User Interface"
        Flutter[Flutter Web/Mobile App]
    end

    subgraph "Local Environment (Docker Compose)"
        direction LR
        LocalGateway[Nginx API Gateway:8080]
        LocalAuth[Auth Service]
        LocalEvents[Events/Tickets Service]
        LocalDB[(PostgreSQL)]

        LocalGateway --> LocalAuth
        LocalGateway --> LocalEvents
        LocalAuth --> LocalDB
        LocalEvents --> LocalDB
    end

    subgraph "AWS Cloud"
        direction LR
        ALB[Application Load Balancer]
        EcsAuth["Auth Service (ECS Fargate)"]
        EcsEvents["Events/Tickets Service (ECS Fargate)"]
        EcsDBInit["DB Init Task (ECS Fargate)"]
        AuroraDB[(Aurora DB)]
        Secrets[AWS Secrets Manager]

        ALB --> EcsAuth
        ALB --> EcsEvents
        EcsAuth --> AuroraDB
        EcsEvents --> AuroraDB
        EcsAuth -- reads secrets --> Secrets
        EcsEvents -- reads secrets --> Secrets
        EcsDBInit -- initializes --> AuroraDB
    end

    subgraph "CI/CD & Registry"
        GHA[GitHub Actions]
        ECR[ECR Registry]
        GHA -- builds & pushes --> ECR
        EcsAuth -- pulls image from --> ECR
        EcsEvents -- pulls image from --> ECR
        EcsDBInit -- pulls image from --> ECR
    end

    Flutter --> LocalGateway
    Flutter --> ALB`

## Tech Stack

| Category      | Technology                                                                                                    |
|---------------|---------------------------------------------------------------------------------------------------------------|
| **Backend**   | Python 3.12, FastAPI, SQLAlchemy, PostgreSQL, Nginx                                                           |
| **Frontend**  | Flutter, Dart, BLoC/Cubit, ```go_router```, ```dio```, ```provider```                                                       |
| **Cloud (AWS)** | ECS Fargate, Aurora Serverless (PostgreSQL), Application Load Balancer (ALB), S3, DynamoDB, Secrets Manager, ECR |
| **DevOps**    | Docker, Docker Compose, Terraform, GitHub Actions                                                             |
| **Testing**   | ```pytest```, ```requests```                                                                                          |

## Project Structure

```
.
├── .github/workflows/      # GitHub Actions CI/CD pipelines
├── backend/
│   ├── api_gateway/        # Nginx configuration for local API gateway
│   ├── db_init/            # Docker service to initialize DB schema and seed data
│   ├── event_ticketing_service/ # Events, tickets, cart, and resale microservice
│   ├── user_auth_service/  # User registration, login, and profile microservice
│   └── tests/              # Pytest integration and smoke tests
├── frontend/               # Flutter application for web and mobile
├── scripts/                # Helper bash scripts for tests and deployment
└── terraform/
    ├── bootstrap/          # Terraform to set up the remote state backend (S3/DynamoDB)
    └── main/               # Main Terraform configuration for all AWS resources
```

## Getting Started (Local Development)

### Backend Setup

Run the entire backend stack (API services, database, and gateway) locally using Docker.

**Prerequisites:**
- Docker
- Docker Compose

**Steps:**
1.  **Clone the Repository**
    ```sh
    git clone https://github.com/KwiatkowskiML/IO2.git
    cd IO2
    ```

2.  **Create ```.env``` File**
    An ```.env``` file is required by Docker Compose to set environment variables for the services. A template is provided.
    ```sh
    cp .env.template .env
    ```
    The default values in ```.env.template``` are configured to work with the local ```docker-compose.yml``` setup.

3.  **Start Services**
    Build and start all services in detached mode.
    ```sh
    docker compose up --build -d
    ```

4.  **Access Services**
    - **API Gateway**: ```http://localhost:8080```
    - **Health Check**: ```http://localhost:8080/health```
    - **PostgreSQL Database**: Connect on ```localhost:5432``` (credentials are in the ```.env``` file).

5.  **View Logs**
    To see the logs from all running containers:
    ```sh
    docker compose logs -f
    ```

6.  **Stop Services**
    To stop all services and remove the network:
    ```sh
    docker compose down
    ```
    To also remove the database volume (deleting all data):
    ```sh
    docker compose down -v
    ```

### Frontend Setup

Run the Flutter application and connect it to the local backend.

**Prerequisites:**
- Flutter SDK

**Steps:**
1.  **Navigate to the Frontend Directory**
    ```sh
    cd frontend
    ```
2.  **Install Dependencies**
    ```sh
    flutter pub get
    ```
3.  **Run the App**
    The ```ApiClient``` in ```lib/core/network/api_client.dart``` is pre-configured to point to ```http://localhost:8080/api```.
    ```sh
    flutter run
    ```

## Running Automated Tests

The project includes a suite of integration tests that run against a live local environment. The ```tests.yml``` workflow runs these automatically.

To run them manually:
1.  Ensure the local backend services are **not** running (```docker compose down```). The test script will manage the lifecycle.
2.  Make the scripts executable:
    ```sh
    chmod +x ./scripts/actions/run_tests.bash ./scripts/utils/print.bash
    ```
3.  Run the test script:
    ```sh
    ./scripts/actions/run_tests.bash local
    ```
    The script will:
    - Start the Docker Compose services.
    - Wait for the API to become available.
    - Execute ```pytest``` against the endpoints.
    - Show service logs if any tests fail.
    - Clean up and stop all services.

## AWS Deployment (Terraform)

Deploy the entire application stack to AWS using Terraform.

### Prerequisites
- AWS Account
- AWS CLI configured with credentials (```aws configure```)
- Terraform

### Step 1: Bootstrap Terraform Backend
This step creates an S3 bucket and a DynamoDB table to store the Terraform state remotely and securely. **This only needs to be done once per AWS account/region.**

1.  Navigate to the bootstrap directory:
    ```sh
    cd terraform/bootstrap
    ```
2.  Initialize Terraform:
    ```sh
    terraform init
    ```
3.  Apply the configuration:
    ```sh
    terraform apply
    ```
    This will create the necessary resources and generate a ```backend_config.json``` file in ```terraform/main```.

### Step 2: Build and Push Docker Images
The Terraform configuration needs the Docker images to be available in AWS ECR.

1.  Make the scripts executable:
    ```sh
    chmod +x ./scripts/actions/build_and_push_all.bash ./scripts/actions/push_docker_to_registry.bash ./scripts/utils/print.bash
    ```
2.  Run the build and push script:
    ```sh
    ./scripts/actions/build_and_push_all.bash
    ```
    This script will:
    - Authenticate Docker with your AWS ECR registry.
    - Create an ECR repository for each service if it doesn't exist.
    - Build each service's Docker image.
    - Tag and push the images to their respective ECR repositories.

### Step 3: Deploy Main Infrastructure
This step provisions all the main resources: VPC, subnets, RDS Aurora database, ECS cluster, Fargate services, and Application Load Balancer.

1.  Navigate to the main Terraform directory:
    ```sh
    cd terraform/main
    ```
2.  Initialize Terraform using the generated backend configuration:
    ```sh
    terraform init -backend-config=backend_config.json
    ```
3.  Apply the configuration. You will be prompted to provide values for variables like ```project_name``` and ```environment```.
    ```sh
    terraform apply
    ```
    After the apply is complete, Terraform will output the ```api_base_url```, which is the public DNS of the Application Load Balancer.

### Resetting the Database
If you need to wipe and re-seed the cloud database, you can run ```terraform apply``` with a special variable:
```sh
# From terraform/main directory
terraform apply -var="force_db_reset=true"
```
This forces the ```db-init``` ECS task to re-run with the ```DB_RESET=true``` flag.

## CI/CD Pipeline

The repository includes a GitHub Actions workflow defined in ```.github/workflows/tests.yml```. This pipeline automatically runs on every ```push``` and ```pull_request``` to the ```main``` and ```dev``` branches.

The workflow performs the following steps:
1.  Checks out the code.
2.  Sets up Python.
3.  Spins up the entire local environment using ```docker compose```.
4.  Waits for the API Gateway to be healthy.
5.  Runs the full ```pytest``` suite against the local environment.
6.  If tests fail, it dumps the logs from all Docker services for easy debugging.
7.  Cleans up all Docker resources.
