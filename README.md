# 🚀 Terraform + Kubernetes + Rancher

## 📋 Project Description

This project implements a complete infrastructure on AWS using Terraform, including:

- **Kubernetes Cluster**: EKS (Elastic Kubernetes Service) with managed nodes
- **Rancher**: Kubernetes management platform deployed via Helm
- **VPC**: Virtual private cloud with public and private subnets
- **Security Groups**: Security configuration for EKS and Rancher

### ⚠️ Stability Improvements

This project includes specific improvements to avoid common issues during `terraform destroy` and `terraform apply`:

- **Configured timeouts** for all Helm and EKS resources (15 minutes for addons)
- **Explicit dependencies** between resources (addons depend on node group)
- **Lifecycle rules** for better destruction handling
- **Automatic conflict resolution** in EKS addons
- **Disabled problematic features** (monitoring, logging, backup)
- **Disabled post-delete job** that causes BackoffLimitExceeded errors
- **Verification and correction scripts** for addons in DEGRADED state
- **Load Balancer**: NGINX Ingress Controller for Rancher access

#### 🔧 Maintenance Scripts

- **`scripts/check-addons.sh`**: Verifies the status of EKS addons
- **`scripts/fix-degraded-addons.sh`**: Fixes addons in DEGRADED state
- **`scripts/cleanup-rancher.sh`**: Manual cleanup for extreme cases

#### 🧹 Manual Cleanup Script

If `terraform destroy` fails with finalizer or stuck job errors:

```bash
# Run cleanup script
./scripts/cleanup-rancher.sh

# Then try destroy again
terraform destroy
```

## 🏗️ Architecture

### **Basic Architecture (Local Access)**
```
┌─────────────────────────────────────────────────────────────────┐
│                           Internet                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                       │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Public        │    │   Private       │                    │
│  │   Subnets       │    │   Subnets       │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │   NAT     │  │    │  │   EKS     │  │                    │
│  │  │ Gateway   │  │    │  │  Nodes    │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │   IGW     │  │    │  │   EKS     │  │                    │
│  │  │           │  │    │  │ Cluster   │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  └─────────────────┘    │                 │                    │
│                         │  ┌───────────┐  │                    │
│                         │  │  Rancher  │  │                    │
│                         │  │   UI      │  │                    │
│                         │  └───────────┘  │                    │
│                         └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

### **Architecture with Load Balancer (Public Access)**
```
┌─────────────────────────────────────────────────────────────────┐
│                           Internet                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                       │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Public        │    │   Private       │                    │
│  │   Subnets       │    │   Subnets       │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │    NLB    │  │    │  │   EKS     │  │                    │
│  │  │ (NGINX)   │  │    │  │  Nodes    │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │   NAT     │  │    │  │   EKS     │  │                    │
│  │  │ Gateway   │  │    │  │ Cluster   │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  │                 │    │                 │                    │
│  │  ┌───────────┐  │    │  ┌───────────┐  │                    │
│  │  │   IGW     │  │    │  │  Rancher  │  │                    │
│  │  │           │  │    │  │   UI      │  │                    │
│  │  └───────────┘  │    │  └───────────┘  │                    │
│  └─────────────────┘    └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

### **Traffic Flow**

#### **Local Access (Port Forward)**
1. **User** → `kubectl port-forward` → **EKS Cluster** → **Rancher Pod**
2. **Security**: Only accessible from local machine
3. **Use**: Development, testing, temporary access

#### **Public Access (Load Balancer)**
1. **User** → **Internet** → **ALB** → **EKS Cluster** → **Rancher Pod**
2. **Security**: SSL/TLS, Security Groups, Route 53
3. **Use**: Production, remote access, multiple users

## 📁 Project Structure

```
terraform-k8s-rancher/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
├── .gitignore
├── LICENSE
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rancher/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

## ⚙️ Deployment Prerequisites

### **Required Tools**

| Tool | Minimum Version | Recommended Version | Installation |
|------|----------------|---------------------|-------------|
| **Terraform** | >= 1.0 | 1.13.3 | [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) |
| **AWS CLI** | v2.0.0+ | v2.13.0+ | [Install AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **kubectl** | >= 1.28 | 1.33.0 | [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) |
| **Helm** | >= 3.0 | 3.12.0 | [Install Helm](https://helm.sh/docs/intro/install/) |
| **Git** | >= 2.0 | 2.40.0+ | [Install Git](https://git-scm.com/downloads) |

### **Prerequisites Verification**

```bash
# Verify Terraform
terraform version
# Should show: Terraform v1.13.3

# Verify AWS CLI
aws --version
# Should show: aws-cli/2.13.0

# Verify kubectl
kubectl version --client
# Should show: Client Version: v1.33.0

# Verify Helm
helm version
# Should show: v3.12.0

# Verify Git
git --version
# Should show: git version 2.40.0
```

### **AWS Configuration**

```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
# Should show your AWS account information
```

## 🚀 Step-by-Step Deployment Guide

### **Step 1: Clone the Repository**
```bash
git clone https://github.com/your-username/terraform-k8s-rancher.git
cd terraform-k8s-rancher
```


### **Step 2: Configure Environment Variables**
```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit variables (IMPORTANT: Change default values)
nano terraform.tfvars
```

**Critical variables to modify:**
```hcl
# In terraform.tfvars
project_name = "my-devops-project"
aws_region   = "us-west-2"

# SECURITY: Change these values
allowed_ssh_ips = [
  "YOUR_PUBLIC_IP/32",  # Replace with your real IP
]

rancher_password = "MySecurePassword123!"  # Change password
```

### **Step 3: Initialize Terraform**
```bash
# Initialize Terraform and download providers
terraform init

# Validate configuration
terraform validate
```

### **Step 4: Plan the Deployment**
```bash
# Create execution plan
terraform plan -out="terraform.tfplan"

# Review the plan before applying
terraform show terraform.tfplan
```

### **Step 5: Deploy the Infrastructure**
```bash
# Apply the plan (this will create all resources)
terraform apply terraform.tfplan

# Or apply directly without plan
terraform apply
```

### **Step 6: Configure kubectl**
```bash
# Get cluster information
terraform output cluster_name
terraform output cluster_endpoint

# Configure kubectl for the EKS cluster
aws eks update-kubeconfig \
  --region us-west-2 \
  --name $(terraform output -raw cluster_name)

# Verify connection
kubectl get nodes
```

### **Step 7: Verify Rancher Deployment**
```bash
# Verify that Rancher is deployed
kubectl get pods -n cattle-system

# Verify services
kubectl get svc -n cattle-system

# Verify Helm releases
helm list -n cattle-system
```

### **Step 8: Access Rancher**

#### **Option A: Local Access (Port Forward)**
```bash
# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name eventim-devops-dev-cluster

# Port forward (both HTTP and HTTPS ports)
kubectl port-forward -n cattle-system svc/rancher 8080:80 8443:443

# In another terminal, get admin password
kubectl get secret rancher-admin-password -n cattle-system -o jsonpath='{.data.password}' | base64 -d
```

**Rancher Access (Local):**
- URL: https://localhost:8443
- Username: `admin`
- Password: `admin123!` (or the one obtained from the previous command)

#### **Option B: Public Access (Load Balancer)**
```bash
# Get Load Balancer URL
kubectl get svc -n cattle-system nginx-ingress-ingress-nginx-controller

# Load Balancer URL: https://[ALB_DNS]
# Access directly in browser (accept self-signed SSL certificate)
```

**Rancher Access (Public):**
- URL: https://[ALB_DNS]
- Username: `admin`
- Password: `admin123!`

#### **Option C: Public Access (Load Balancer) - With Domain and SSL**
```bash
# Enable public access with domain and SSL
enable_public_access = true
rancher_domain      = "rancher.your-domain.com"
route53_zone_id     = "Z1234567890ABC"  # Your Route 53 zone ID
enable_ssl          = true

# Apply changes
terraform apply
```

**Rancher Access (Public - With Domain and SSL):**
- URL: https://rancher.your-domain.com
- Username: `admin`
- Password: The one obtained from the previous command


## 🔧 Detailed Configuration

### **Configuration Options**

#### **1. Local Access Only (Default)**
```hcl
# terraform.tfvars
enable_public_access = false
```
- ✅ **Advantages**: Most secure, no additional costs
- ✅ **Access**: `kubectl port-forward` to localhost
- ❌ **Disadvantages**: Only accessible from local machine

#### **2. Public Access (NGINX Ingress NLB)**
```hcl
# terraform.tfvars
enable_public_access = true
```
- ✅ **Advantages**: Public access, simple configuration, cost-effective
- ✅ **URL**: https://[NLB_DNS] (via NGINX Ingress)
- ❌ **Disadvantages**: Long URL, self-signed certificate

### Main Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `project_name` | Project name | `eventim-devops` |
| `aws_region` | AWS region | `us-west-2` |
| `vpc_cidr` | VPC CIDR | `10.0.0.0/16` |
| `cluster_version` | Kubernetes version | `1.33` |
| `node_group_instance_types` | Instance types | `["t3.medium"]` |
| `rancher_hostname` | Rancher hostname | `rancher.local` |
| `rancher_password` | Admin password | `admin123!` |
| `enable_public_access` | Enable public access via NLB | `false` |



## 🏗️ Terraform Modules

### **VPC Module**
- Creates VPC with public and private subnets
- Configures Internet Gateway and NAT Gateways
- Establishes route tables

### **Security Groups Module**
- Security Group for EKS Cluster
- Security Group for EKS Nodes
- Security Group for Rancher Load Balancer
- Optimized security rules

### **EKS Module**
- EKS Cluster with logging enabled
- Node Group with auto-scaling
- Add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver
- IAM roles and policies

### **Rancher Module**
- Rancher deployment via Helm
- NGINX Ingress Controller with NLB
- Secret for admin password


## 🧪 Testing and Verification

### 1. **Verify EKS Cluster**
```bash
# Verify cluster nodes
kubectl get nodes

# Verify all pods
kubectl get pods -A
```

### 2. **Verify Rancher**
```bash
# Verify Rancher pods
kubectl get pods -n cattle-system

# Verify services
kubectl get svc -n cattle-system

# Verify Ingress
kubectl get ingress -n cattle-system
```

### 3. **Verify Helm Releases**
```bash
# List Helm releases
helm list -n cattle-system
```

### 4. **Final Verification - Rancher Access**
```bash
# Test local access
curl -k https://localhost:8443

# Test public access
curl -k https://[ALB_DNS]

# Both should return JSON with Rancher API
```

## 🔒 Security

- **Private VPC**: EKS nodes in private subnets
- **Security Groups**: Minimal necessary rules
- **IAM Roles**: Specific permissions for each service
- **Encryption**: In transit and at rest
- **Let's Encrypt**: Automatic SSL/TLS for Rancher

## 📊 Monitoring

- **CloudWatch Logs**: EKS cluster logs
- **Rancher Monitoring**: Kubernetes metrics
- **Rancher Logging**: Log centralization
- **Rancher Backup**: Automatic backups

## 📚 Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Rancher Documentation](https://rancher.com/docs/)
- [Helm Documentation](https://helm.sh/docs/)
