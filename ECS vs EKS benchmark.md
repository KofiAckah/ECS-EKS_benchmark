# The "Poly-Orchestrator" challenge - ShopNow

**Scenario:** You are a DevOps Engineer for "ShopNow," a startup running a 3-tier e-commerce application (Frontend, Backend API, Redis, Postgres). The CTO wants to benchmark AWS ECS (Fargate) against Amazon EKS to decide which orchestrator suits the company best.

---

## Objectives

- Containerize a multi-tier application
- Deploy the same application to both Amazon ECS (Fargate) and Amazon EKS
- Implement Service Discovery and Load Balancing in both environments

---

## Instructions

**1. Containerization**

Create Dockerfiles for a sample Python/Node.js frontend and backend. Create a `docker-compose.yml` to verify it runs locally.

**2. Infrastructure as Code (IaC)**

Use Terraform or CloudFormation to provision the network (VPC, Subnets) and the clusters (ECS Cluster and EKS Cluster).

**3. ECS deployment**

Create Task Definitions and Services. Ensure the Frontend talks to the Backend via Service Discovery (Cloud Map) or Internal Load Balancer.

**4. EKS deployment**

Create Kubernetes manifests (Deployments, Services, Ingress). Deploy the app to EKS.

**5. Resiliency**

Manually kill a container/pod in both environments and demonstrate that the application recovers automatically.

---

> Make sure to document everything in this project. Submission includes documentation and a live walkthrough.
