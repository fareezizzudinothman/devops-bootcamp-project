# 🚀 DevOps Bootcamp Project

<p align="center">
  <img src="docs/architecture.png" alt="DevOps CI/CD Architecture" width="100%">
</p>


Hai Cikgu Arif, 

Ini cara nak jalankan apps SHIP ni.

1) Clone Repo ini di local PC.
2) Masuk ke folder terraform dan jalan kan (terrafom init, terraform validate,terraform plan) seterus itu (terraform apply -auto-approve).
3) Setelah selesai di Local PC akan ada updated iniventory.ini dalam Ansible folder.
4) Cipta Branch baharu (git checkout -b "initial") add dan commit inventory.ini (git add inventory.ini && git commit -m 'initial setup').
5) Push commit tersebut (git push origin initial) dan create PR (gh pr create --fill) untuk jalan kan CI dan Merge PR (gh pr merge --squash -auto-delete) untuk jalan kan CD.
6) Di github bahagian action anda akan nampak process CICD berjalan.
7) Dalam process CDCI akan jalan kan ansible playbooks untuk setup docker dan nginx di webserver dan prometheus, grafana, cloudflared di monitoring server.
8) Login di cloudflare dan add record DNS baru dan masuk kan public IP untuk webserver .Boleh dapat kan Public IP di (terraform output).
9) Untuk monitoring pulak boleh setup cloudflare tunnel, dpaat kan tunnel-token dan masuk kan internal IP monitoring server. 
10)Segala perubahan dalam file ansible boleh di lakukan di local PC sahaja dan push ke github. Github kan jalankan CICD dan deploy akan berjalan di ansible controller server secara automatic dan tidak perlu SSM ke ansible server untuk jalan kan ansible playbooks.
11)Boleh SSM ke Ansible controller server untuk run command di webserver dan monitoring server. 
10) Untuk apps boleh di access melalui https://kapal.fareezizzudinothman.com
11) Untuk monitoring prometheus di access melalui https://prometheus.fareezizzudinothman.com
12)Untuk monitoring Grafana di access melalui https://grafana.fareezizzudinothman.com (username = admin, password =admin)


# AWS DevOps Bootcamp Project

A complete AWS DevOps project demonstrating **Infrastructure as Code, configuration management, containerization, private container registry, AWS Systems Manager, monitoring, and GitHub Actions CI/CD**.

---

## 🏗️ Architecture

![Architecture](docs/architecture.png)

The main idea of the architecture is:

```text
                         GitHub
                            |
                            | git push origin main
                            v
                    GitHub Actions
                            |
                    Docker Build & Push
                            |
                            v
                       Amazon ECR
                            |
                       AWS SSM
                            |
                            v
                  ┌─────────────────┐
                  │     Node 2      │
                  │ Ansible Control │
                  │   10.0.0.135    │
                  └────────┬────────┘
                           |
                    Ansible + AWS SSM
                     /               \
                    v                 v
          ┌─────────────────┐  ┌──────────────────┐
          │     Node 1      │  │      Node 3      │
          │  Web / App      │  │    Monitoring    │
          │   10.0.0.5      │  │    10.0.0.136    │
          │                 │  │                  │
          │ Docker :80      │  │ Prometheus :9090 │
          │ Node Exporter   │  │ Grafana :3000    │
          │     :9100       │  │ Node Exporter    │
          └─────────────────┘  │ Cloudflared      │
                               └────────┬─────────┘
                                        |
                                Cloudflare Tunnel
                                        |
                                        v
                         grafana.fareezizzudinothman.com
```

**Important:** Node 2 is the Ansible Control Node. It manages Node 1 and Node 3 through the `amazon.aws.aws_ssm` connection. The inventory groups Node 1 as `webservers`, Node 2 as `ansible`, and Node 3 as `monitoring`. 

---

# 🔄 End-to-End Process

The complete deployment process is:

```text
Developer
    |
    | git push origin main
    v
GitHub
    |
    v
GitHub Actions
    |
    ├── Checkout source
    ├── GitHub OIDC → AWS
    ├── Login to Amazon ECR
    ├── Docker build
    └── Docker push
            |
            v
        Amazon ECR
            |
            | SSM SendCommand
            v
          Node 2
     Ansible Controller
            |
            v
        deploy.sh <SHA>
            |
            ├── git pull
            ├── install Ansible dependencies
            ├── deploy application
            ├── deploy Node Exporter
            ├── deploy monitoring
            └── deploy Cloudflare Tunnel
                    |
                    v
                  Ansible
                 /       \
                /         \
               v           v
            Node 1       Node 3
          Web / App     Monitoring
```

---

# ☁️ AWS Infrastructure

Infrastructure is provisioned using **Terraform**.

## Network

```text
VPC
10.0.0.0/24
|
+-- Public Subnet
|   10.0.0.0/25
|   |
|   +-- Node 1
|       10.0.0.5
|
+-- Private Subnet
    10.0.0.128/25
    |
    +-- Node 2
    |   10.0.0.135
    |
    +-- Node 3
        10.0.0.136
```

AWS Region:

```text
ap-southeast-1
```

### EC2 Nodes

| Node | Private IP | Role | Network |
|---|---|---|---|
| Node 1 | `10.0.0.5` | Web / Application | Public subnet |
| Node 2 | `10.0.0.135` | Ansible Controller | Private subnet |
| Node 3 | `10.0.0.136` | Monitoring | Private subnet |

Node 1 has an Elastic IP.

Node 2 and Node 3 remain in the private subnet.

## Terraform Components

Terraform manages:

- VPC
- Public subnet
- Private subnet
- Internet Gateway
- NAT Gateway
- Route tables
- Security Groups
- Elastic IP
- EC2 instances
- IAM roles and instance profiles
- Amazon ECR
- GitHub OIDC provider
- S3 Terraform backend

The Terraform backend stores the Terraform state in S3 and uses the backend lock file mechanism.

---

# 🔐 IAM Design

IAM roles are separated according to each component's responsibility.

```text
Node 1
└── devops-webserver-role
    ├── AmazonSSMManagedInstanceCore
    └── AmazonEC2ContainerRegistryReadOnly

Node 2
└── devops-ansible-role
    ├── AmazonSSMManagedInstanceCore
    ├── SSM permissions
    └── S3 permissions for Ansible SSM

Node 3
└── devops-monitoring-role
    ├── AmazonSSMManagedInstanceCore
    └── ssm:GetParameter for Cloudflare token

GitHub Actions
└── devops-github-actions-role
    ├── ECR push
    ├── SSM deployment
    └── EC2 instance discovery
```

There is also an SSM role/profile defined in Terraform as a general SSM role.

## GitHub OIDC

GitHub Actions does not use a long-lived AWS access key.

Authentication works like this:

```text
GitHub Actions
      |
      v
GitHub OIDC
      |
      v
AWS STS
      |
      v
devops-github-actions-role
      |
      +── Amazon ECR
      +── AWS SSM
      +── EC2 DescribeInstances
```

---

# 🐳 Docker

The application is containerized using Docker.

```text
app/
└── Dockerfile
```

The image is built from the `app` directory by GitHub Actions.

Instead of using only `latest`, the project uses the Git commit SHA:

```text
devops-bootcamp-app:<GITHUB_SHA>
```

Example:

```text
devops-bootcamp-app:6f11164e72c40613fe1776459e41fb8de1c20aa8
```

This allows each deployment to be linked to a specific Git commit.

---

# 📦 Amazon ECR

Amazon Elastic Container Registry is the private Docker registry for the application.

Repository:

```text
devops-bootcamp-app
```

The repository is configured with:

- Immutable image tags
- Scan on push
- `force_delete = true` for the current development setup

Image format:

```text
990723917403.dkr.ecr.ap-southeast-1.amazonaws.com/devops-bootcamp-app:<GITHUB_SHA>
```

The image is pushed by GitHub Actions and pulled by Node 1 during deployment.

---

# ⚙️ Ansible

Node 2 acts as the **Ansible Control Node**.

Ansible is responsible for configuring and deploying Node 1 and Node 3.

```text
                     Node 2
                Ansible Controller
                      |
             amazon.aws.aws_ssm
                      |
              AWS Systems Manager
                 /            \
                v              v
             Node 1          Node 3
             App          Monitoring
```

Ansible uses AWS SSM instead of SSH.

The inventory is generated by Terraform and contains the private IP and EC2 instance ID for each node.

```text
[webservers]
node1

[ansible]
node2

[monitoring]
node3

[nodes:children]
webservers
ansible
monitoring
```

The Ansible connection is:

```text
amazon.aws.aws_ssm
```

---

# 📚 Ansible Galaxy

The project uses Ansible Galaxy dependencies.

Main components:

```text
geerlingguy.docker
prometheus.prometheus
community.docker
amazon.aws
```

These provide reusable roles and AWS/Docker functionality.

---

# 🚀 Ansible Deployment

The application deployment playbook configures Node 1.

Main steps:

```text
Install Docker
      ↓
Install required packages
      ↓
Check / install AWS CLI
      ↓
Create ssm-user
      ↓
Add ssm-user to docker group
      ↓
Install Python Docker SDK
      ↓
Login to Amazon ECR
      ↓
Pull application image
      ↓
Remove old container
      ↓
Start new container
```

The application container is started with:

```text
80:80
```

So the application is exposed through port `80` on Node 1.

---

# 📋 deploy.sh

`deploy.sh` is the deployment entry point on Node 2.

GitHub Actions sends the command to Node 2 through SSM:

```text
SSM SendCommand
      |
      v
Node 2
      |
      v
deploy.sh <IMAGE_TAG>
```

The script then:

```text
git pull origin main
        ↓
ansible-galaxy install -r requirements.yml
        ↓
Application deployment
        ↓
Node Exporter deployment
        ↓
Monitoring deployment
        ↓
Cloudflare deployment
```

The image tag is passed to Ansible:

```text
image_tag=<GITHUB_SHA>
```

The same image tag is therefore used when deploying the application to Node 1.

---

# 🔁 CI/CD Pipeline

Workflow:

```text
.github/workflows/cicd.yaml
```

## Pull Request

For a Pull Request, GitHub Actions runs:

```text
Checkout
   ↓
Setup Node.js 22
   ↓
npm ci
   ↓
npm test
   ↓
npm run test:unit
   ↓
npm run build
```

This validates the application before merging.

## Push to Main

When code is pushed to `main`:

```text
Checkout
   ↓
GitHub OIDC Authentication
   ↓
Amazon ECR Login
   ↓
Create image tag using GITHUB_SHA
   ↓
Docker Build
   ↓
Docker Push to ECR
   ↓
Find running Node 2
   ↓
SSM SendCommand
   ↓
deploy.sh <GITHUB_SHA>
   ↓
Wait for SSM result
   ↓
Deployment Success / Failure
```

GitHub Actions dynamically finds Node 2 using its `Name=node2` tag instead of hard-coding the EC2 instance ID.

---

# 📊 Monitoring

Monitoring is hosted on Node 3.

```text
Node 1
Node Exporter :9100
       |
       |
Node 2
Node Exporter :9100
       |
       |
Node 3
Node Exporter :9100
       |
       v
 Prometheus :9090
       |
       v
 Grafana :3000
```

Node Exporter is installed on all nodes using:

```text
prometheus.prometheus.node_exporter
```

Prometheus scrapes:

```text
10.0.0.5:9100
10.0.0.135:9100
10.0.0.136:9100
```

The Prometheus scrape interval is:

```text
15 seconds
```

---

# 📈 Prometheus

Prometheus runs on Node 3.

```text
10.0.0.136:9090
```

Its main responsibility is collecting and storing metrics from Node Exporter.

Targets:

```text
Node 1 → 10.0.0.5:9100
Node 2 → 10.0.0.135:9100
Node 3 → 10.0.0.136:9100
```

---

# 📊 Grafana

Grafana runs on Node 3:

```text
10.0.0.136:3000
```

Grafana uses Prometheus as the monitoring data source.

The monitoring stack is deployed using Docker Compose.

```text
Node 3
 |
 +-- Prometheus :9090
 |
 +-- Grafana :3000
 |
 +-- Cloudflared
```

---

# ☁️ Cloudflare Tunnel

Node 3 does not need a public IP for Grafana access.

Cloudflare Tunnel provides the external connection:

```text
Internet
    |
    v
Cloudflare
    |
    v
Cloudflare Tunnel
    |
    v
Node 3
    |
    v
Grafana :3000
```

Public Grafana URL:

```text
https://grafana.fareezizzudinothman.com
```

The Cloudflare Tunnel token is stored in AWS Systems Manager Parameter Store:

```text
/devops-bootcamp-2026/tunnel-token
```

Ansible retrieves the token from SSM and stores it on Node 3 for the Cloudflared container.

The token is not hard-coded in the Terraform or Ansible configuration.

---

# 🐳 Monitoring Docker Compose

Node 3 runs the monitoring stack using Docker Compose:

```text
compose.yaml
 |
 +-- Prometheus
 |
 +-- Grafana
 |
 +-- Cloudflared
```

Prometheus uses the project configuration:

```text
prometheus.yaml
```

Grafana data is stored in a Docker volume:

```text
grafana-data
```

---

# 🔌 Main Ports

| Port | Component | Node |
|---|---|---|
| `80` | Application | Node 1 |
| `9100` | Node Exporter | Node 1, Node 2, Node 3 |
| `9090` | Prometheus | Node 3 |
| `3000` | Grafana | Node 3 |

---

# 📁 Project Structure

```text
devops-bootcamp-project/
│
├── README.md
│
├── app/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   ├── index.html
│   ├── public/
│   ├── src/
│   └── scripts/
│
├── ansible/
│   ├── ansible.cfg
│   ├── deploy.sh
│   ├── inventory.ini
│   ├── requirements.yml
│   │
│   ├── Monitoring/
│   │   ├── compose.yaml
│   │   └── prometheus.yaml
│   │
│   └── playbooks/
│       ├── playbooks-nginx-deploy.yaml
│       ├── playbooks-node-exporter.yaml
│       ├── playbooks-monitoring.yaml
│       └── playbooks-cloudflare.yaml
│
├── terraform/
│   ├── providers.tf
│   ├── network.tf
│   ├── security.tf
│   ├── ec2.tf
│   ├── iam.tf
│   ├── ecr.tf
│   ├── inventory.tf
│   ├── inventory.ini.tftpl
│   ├── outputs.tf
│   └── userdata-ansible.sh
│
├── docs/
│   ├── architecture.png
│   └── architecture1.png
│
└── .github/
    └── workflows/
        └── cicd.yaml
```

---

# 🛠️ Setup From Scratch

## 1. Clone Repository

```bash
git clone https://github.com/fareezizzudinothman/devops-bootcamp-project.git
cd devops-bootcamp-project
```

## 2. Configure AWS

Make sure AWS CLI is configured:

```bash
aws configure
```

Verify:

```bash
aws sts get-caller-identity
```

## 3. Deploy Infrastructure

```bash
cd terraform

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After deployment:

```bash
terraform output
```

Important outputs include:

```text
web_server_elastic_ip_node1
node1_private_ip_webserver
node2_private_ip_ansible
node3_private_ip_monitoring
ecr_repository_url
```

---

# 🖥️ Node 2 Bootstrap

Node 2 is automatically prepared through Terraform user data.

The bootstrap process:

```text
Wait for Internet / NAT
        ↓
apt update
        ↓
Install Ansible
Install Git
Install curl
Install unzip
Install Python
        ↓
Install AWS CLI v2
        ↓
Install Session Manager Plugin
        ↓
Install amazon.aws Ansible collection
        ↓
Verify amazon.aws.aws_ssm
        ↓
Clone GitHub repository
```

This allows Node 2 to become the Ansible Controller after the EC2 instance is created.

---

# 🔑 Access Private Servers

Node 2 and Node 3 can be accessed through AWS SSM.

Example:

```bash
aws ssm start-session --target <INSTANCE_ID>
```

Terraform also provides SSM commands through its outputs.

---

# 🧪 Verification

## Check Application

```bash
curl http://10.0.0.5
```

## Check Node Exporter

```bash
curl http://10.0.0.5:9100/metrics
curl http://10.0.0.135:9100/metrics
curl http://10.0.0.136:9100/metrics
```

## Check Prometheus

```bash
curl http://10.0.0.136:9090/-/healthy
```

Expected:

```text
Prometheus Server is Healthy.
```

## Check Containers

On Node 1:

```bash
docker ps
```

On Node 3:

```bash
docker ps
```

Expected services on Node 3:

```text
prometheus
grafana
cloudflared
```

## Check Prometheus Targets

Open Prometheus:

```text
http://10.0.0.136:9090
```

Go to:

```text
Status → Targets
```

The Node Exporter targets should show:

```text
UP
```

---

# 🚀 Normal Deployment

After making application changes:

```bash
git add .
git commit -m "update application"
git push origin main
```

The rest of the deployment is automated:

```text
Git Push
   ↓
GitHub Actions
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
AWS SSM
   ↓
Node 2
   ↓
deploy.sh
   ↓
Ansible
   ↓
Node 1
   ↓
New Docker Container
   ↓
Application Live
```

---

# 🎯 Components Summary

| Component | Purpose |
|---|---|
| **Terraform** | Infrastructure as Code |
| **AWS VPC** | Network isolation |
| **Public Subnet** | Hosts Node 1 |
| **Private Subnet** | Hosts Node 2 and Node 3 |
| **NAT Gateway** | Outbound Internet access for private subnet |
| **Security Groups** | Network firewall |
| **EC2** | Compute nodes |
| **IAM** | AWS permissions |
| **AWS SSM** | Server management and Ansible connection |
| **GitHub OIDC** | Secure GitHub-to-AWS authentication |
| **GitHub Actions** | CI/CD automation |
| **Amazon ECR** | Private Docker registry |
| **Docker** | Application and monitoring containers |
| **Ansible** | Configuration management and deployment |
| **Node Exporter** | System metrics |
| **Prometheus** | Metrics collection and storage |
| **Grafana** | Monitoring visualization |
| **Cloudflare Tunnel** | External access to Grafana |

---

# 🧠 DevOps Concepts Demonstrated

This project demonstrates practical implementation of:

- Infrastructure as Code
- Configuration Management
- CI/CD
- Containerization
- Docker image versioning
- Private container registry
- AWS IAM
- GitHub OIDC
- AWS Systems Manager
- Public and private networking
- NAT Gateway
- Security Groups
- Automated server provisioning
- Ansible automation
- Monitoring
- Metrics collection
- Cloudflare Tunnel
- Infrastructure recreation

---

# 📌 Deployment Principle

The key deployment principle is:

```text
Git Commit
    ↓
GitHub Actions
    ↓
Docker Image
    ↓
Amazon ECR
    ↓
AWS SSM
    ↓
Node 2
    ↓
Ansible
    ↓
Node 1 / Node 3
```

The application deployment uses the **Git commit SHA as the Docker image tag**, making it possible to identify which source version is running on Node 1.

---

# 🏁 Final Result

The final environment provides an automated DevOps workflow:

```text
                    ┌─────────────┐
                    │   GitHub    │
                    └──────┬──────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ GitHub Actions  │
                  └────────┬────────┘
                           │
                           ▼
                     Amazon ECR
                           │
                           ▼
                      AWS SSM
                           │
                           ▼
                  ┌─────────────────┐
                  │     Node 2      │
                  │ Ansible Control │
                  └────────┬────────┘
                           │
                 ┌─────────┴─────────┐
                 │                   │
                 ▼                   ▼
             Node 1               Node 3
            Web / App           Monitoring
                                  │
                         ┌────────┼────────┐
                         │        │        │
                    Prometheus Grafana Cloudflare
                         │        │     Tunnel
                         └────────┴────────┘
                                  │
                                  ▼
                    Grafana Public Access
```

The main goal is to make the infrastructure **reproducible** and the application deployment **automated**, while keeping the application and monitoring servers separated by responsibility.
