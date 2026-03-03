# ⚡ Pulse

A production-style AWS platform built with deliberate architectural decisions at every layer.

Pulse is a containerized Python API deployed on ECS Fargate inside a custom VPC, with a Jenkins CI/CD pipeline that builds, tests, and deploys automatically. A Python Lambda actively monitors the health endpoint and publishes alerts via SNS if the service degrades. All infrastructure is defined in Terraform with modular, multi-environment structure.

Every component exists for a reason. Every decision has a tradeoff. That's the standard this project is built to.

---

## Architecture

```
                         ┌──────────────────────────────────────────┐
                         │                 AWS VPC                  │
                         │                                          │
                         │  ┌─────────────────┐  ┌───────────────┐ │
Internet ──► ALB ───────►│  │  Public Subnets  │  │Private Subnets│ │
                         │  │   (ALB lives     │  │ (ECS tasks,   │ │
                         │  │    here)         │  │  Lambda)      │ │
                         │  └─────────────────┘  └───────────────┘ │
                         │           │ NAT Gateway ▲               │
                         └───────────┼─────────────┼───────────────┘
                                     │             │
                              Jenkins Pipeline   Lambda Health Monitor
                         (Lint→Test→Build→Push→Deploy)  (polls /health → SNS)
```

**Stack:**
`Python Flask` → `Docker` → `ECR` → `ECS Fargate` → `ALB` → `VPC` → `Terraform` → `Jenkins` → `CloudWatch` → `Secrets Manager` → `Lambda` → `SNS`

---

## Key Architectural Decisions

These are not defaults. Each one was chosen over an alternative for a specific reason.

### ECS Fargate over EC2
Fargate is serverless compute for containers — AWS manages the underlying instances. That means no cluster capacity planning, no instance patching, no right-sizing EC2 families. The tradeoff is cost: Fargate is more expensive per compute unit than EC2. For this architecture, that's the right call — operational overhead is a larger cost than compute at this scale, and the CI/CD pipeline deploys frequently enough that managed compute pays for itself.

### Custom VPC over Default
The AWS default VPC puts everything in public subnets. There's no private subnet structure, no deliberate routing, no meaningful security boundary. A custom VPC means every CIDR block, every subnet, every route table entry is an explicit decision that can be audited and defended. If something is reachable, it's reachable because it was designed to be.

### ALB in Public Subnets, ECS Tasks in Private Subnets
The ALB is the only entry point from the internet. ECS tasks have no public IP addresses and are not directly reachable — all inbound traffic must pass through the ALB. Private subnet tasks route outbound traffic through a NAT Gateway, which means they can pull images, call external APIs, and reach AWS services, but nothing on the internet can initiate an inbound connection to them directly. The attack surface is the ALB — not the compute.

### Lambda Monitor Inside the VPC
The Lambda health monitor is deployed inside the VPC in a private subnet. It calls the ALB's public endpoint — the same path a real user would take — and alerts via SNS if the response is non-200. Deploying it inside the VPC costs a NAT Gateway but keeps all compute within a single security boundary and preserves the ability to reach private resources if the architecture grows. A Lambda outside the VPC is simpler and cheaper today but inconsistent in posture and limited in future flexibility.

### Task Role and Execution Role are Separate
The ECS execution role is what AWS uses to pull the container image from ECR and write logs to CloudWatch. The task role is what the application code uses at runtime — reading from Secrets Manager, publishing to SNS. Conflating them means granting AWS-internal permissions to application code. Keeping them separate means each role has exactly the permissions it needs and nothing else.

### Terraform State per Environment
Dev and prod have separate S3 backends and separate DynamoDB lock tables. A failed dev operation cannot corrupt prod state. Environments are isolated by design, not by convention.

---

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Lightweight health check — never fails unless the app is genuinely broken. Used by ALB target group and Lambda monitor. |
| `GET /metrics` | Structured service metrics — CPU, memory, request rate. |
| `GET /status` | Environment metadata — region, environment name, ECS task info. |

---

## Project Structure

```
pulse/
├── infra/
│   ├── modules/
│   │   ├── vpc/              # VPC, subnets, IGW, NAT Gateway, route tables, security groups
│   │   └── ecs-service/      # ECS cluster, task definition, service, ALB, target group
│   └── envs/
│       ├── dev/              # Dev environment — auto-deploys on merge
│       └── prod/             # Prod environment — manual approval gate before apply
├── src/
│   └── api/
│       ├── app.py            # Flask application
│       ├── Dockerfile        # Pinned base image, non-root user, layer-optimized
│       ├── requirements.txt
│       └── tests/            # pytest suite — pipeline fails if tests fail
├── lambda/
│   └── health_monitor.py     # Active health polling — catches app-level failures ALB won't
├── Jenkinsfile               # Seven-stage pipeline: Lint → Test → Build → Push → Plan → Deploy → Verify
└── README.md
```

---

## Build Layers

| Layer | What | Status |
|-------|------|--------|
| 1 | VPC & Networking Foundation | 🔲 In Progress |
| 2 | Python API + Docker | 🔲 Not Started |
| 3 | ECR + ECS Fargate Deployment | 🔲 Not Started |
| 4 | Jenkins CI/CD Pipeline | 🔲 Not Started |
| 5 | Observability & Lambda Monitor | 🔲 Not Started |

---

## Infrastructure Design

- **Terraform** — modular structure, reusable across environments
- **State management** — S3 backend with DynamoDB locking, isolated per environment
- **Secrets** — AWS Secrets Manager, pulled at runtime by task role. No credentials in environment variables, no credentials in code.
- **IAM** — least privilege throughout. Task role and execution role are explicitly separate.
- **Container security** — non-root user, pinned base image version, ECR image scanning on push
