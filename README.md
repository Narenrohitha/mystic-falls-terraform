<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/amazonwebservices/amazonwebservices-original-wordmark.svg" alt="AWS" width="120"/>

# 🏗️ Mystic Falls + Clock Tower
### Production-Grade Dual-VPC AWS Architecture

*Built entirely with Terraform. Two regions. One command.*

<br/>

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

<br/>

| 🌐 2 VPCs | 🏠 2 Regions | ⚡ 73 Resources | ⏱️ ~20 Min Deploy |
|:---:|:---:|:---:|:---:|
| Mystic Falls + Clock Tower | us-east-1 + us-east-2 | Fully automated | Single terraform apply |

</div>

---

<div align="center">

## 🗺️ Architecture

</div>

```
                              👤 Users
                                 │
                    ┌────────────▼────────────┐
                    │    🛡️  AWS WAF v2        │  Blocks SQLi · XSS · Rate Limits
                    └────────────┬────────────┘
                                 │
               ┌─────────────────▼─────────────────┐
               │        🌐 Internet Gateway         │  us-east-1
               └─────────────────┬─────────────────┘
                                 │
               ┌─────────────────▼─────────────────┐     🔗 VPC Peering     ┌──────────────────────────┐
               │      ⚖️  Application Load Balancer │◄──────────────────────►│   🏰 Clock Tower VPC     │
               │     HTTP · Health Checks · 2 AZs   │   Private AWS Tunnel   │   192.168.0.0/24         │
               └──────────┬──────────────┬──────────┘                        │   us-east-2b             │
                          │              │                                    ├──────────────────────────┤
             ┌────────────▼──┐    ┌──────▼────────────┐                     │  🖥️ CT Server 1 (public) │
             │ 🖥️ Web Server 1│    │  🖥️ Web Server 2  │                     │  🖥️ CT Server 2 (private)│
             │  private-1a   │    │   private-1b      │                     └──────────────────────────┘
             └────────────┬──┘    └──────┬────────────┘
                          └──────┬───────┘
               ┌─────────────────▼─────────────────┐
               │       🗄️  Amazon RDS MySQL 8.0     │
               │  🟢 Primary (1a) + 🔵 Replica (1b) │
               │   Encrypted · gp3 · Auto-scaling   │
               └───────────────────────────────────┘

  📋 CloudTrail ──► 🪣 S3 ──► λ Lambda ──► 📣 SNS Alerts
  📊 VPC Flow Logs ──► 👁️ CloudWatch Log Group
  ⚡ DynamoDB  ·  🔐 Secrets Manager  ·  👤 IAM Roles
  🏠 Bastion Host  ·  🔒 5 Security Groups
```

---

<div align="center">

## 📦 Services Deployed

</div>

<table>
<tr>
<td valign="top" width="50%">

### 🔒 Security
| Service | Detail |
|---|---|
| **WAF v2** | Common Rules + KnownBadInputs + Rate Limit |
| **Security Groups** | ALB → Web → RDS strict chain |
| **Bastion Host** | SSH jump box, your IP only |
| **Secrets Manager** | DB credentials, 7-day recovery |
| **IAM Roles** | Flow Log + Lambda + CloudTrail |

### 🌐 Networking
| Service | Detail |
|---|---|
| **VPC × 2** | Non-overlapping CIDRs |
| **Subnets** | Public / Private / DB — 2 AZs |
| **VPC Peering** | Cross-region private tunnel |
| **NAT Gateway** | Private subnet outbound |
| **Internet Gateway** | Public entry point |

</td>
<td valign="top" width="50%">

### ⚙️ Compute
| Service | Detail |
|---|---|
| **ALB** | Cross-AZ, health checks |
| **Bastion** | 1 × t3.micro public subnet |
| **Web Servers** | 2 × t3.micro private subnets |
| **Clock Tower** | 2 × t3.micro (pub + priv) |

### 📊 Observability & Data
| Service | Detail |
|---|---|
| **CloudTrail** | Multi-region API audit |
| **CloudWatch** | VPC Flow Logs destination |
| **S3** | Encrypted log storage |
| **Lambda** | Python 3.12 log processor |
| **SNS** | Email alerts pipeline |
| **DynamoDB** | PAY_PER_REQUEST + PITR |

</td>
</tr>
</table>

---

<div align="center">

## 🗂️ Project Structure

</div>

```
📁 mystic-falls-terraform/
│
├── 📄 main.tf                      ← Root — wires all 12 modules together
├── 📄 variables.tf                 ← All input variable declarations
├── 📄 outputs.tf                   ← Endpoints printed after deploy
├── 📄 terraform.tfvars.example     ← Safe template (commit this)
├── 📄 terraform.tfvars             ← Your secrets (NEVER commit this)
├── 📄 .gitignore                   ← Keeps tfvars and state out of git
├── 📄 LICENSE                      ← MIT
│
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 terraform.yml       ← CI/CD: plan on PR · apply on merge
│
└── 📁 modules/
    ├── 📁 vpc/                     ← VPC + Internet Gateway + Flow Logs
    │   └── vpc.tf
    ├── 📁 subnets/                 ← 6 subnets + NAT Gateway + Route tables
    │   └── subnets.tf
    ├── 📁 security_groups/         ← 5 security groups (ALB/Bastion/Web/RDS/CT)
    │   └── security_groups.tf
    ├── 📁 peering/                 ← Cross-region VPC Peering + routes
    │   └── peering.tf
    ├── 📁 waf/                     ← WAFv2 Web ACL + ALB association
    │   └── waf.tf
    ├── 📁 alb/                     ← ALB + Target Group + HTTP Listener
    │   └── alb.tf
    ├── 📁 ec2/                     ← Bastion Host + Web Servers
    │   └── ec2.tf
    ├── 📁 rds/                     ← MySQL 8.0 Primary + Replica
    │   └── rds.tf
    ├── 📁 iam/                     ← IAM User + 3 Roles
    │   └── iam.tf
    ├── 📁 logging/                 ← CloudTrail + S3 + Lambda + SNS + CW
    │   └── logging.tf
    ├── 📁 dynamodb/                ← DynamoDB table (PITR + encrypted)
    │   └── dynamodb.tf
    └── 📁 secrets/                 ← Secrets Manager (DB credentials)
        └── secrets.tf
```

---

<div align="center">

## ⚡ Quick Start

</div>

### 1️⃣ — Prerequisites

```bash
# Check versions
terraform --version   # needs >= 1.5.0
aws --version         # needs >= 2.x

# Configure AWS credentials
aws configure
```

### 2️⃣ — Create EC2 Key Pairs in BOTH regions

```bash
# us-east-1 (Mystic Falls)
aws ec2 create-key-pair --region us-east-1 --key-name my-keypair \
  --query 'KeyMaterial' --output text > my-keypair.pem

# us-east-2 (Clock Tower)
aws ec2 create-key-pair --region us-east-2 --key-name my-keypair \
  --query 'KeyMaterial' --output text > my-keypair-east2.pem

chmod 400 my-keypair.pem my-keypair-east2.pem
```

### 3️⃣ — Get latest AMI IDs for both regions

```bash
# us-east-1
aws ec2 describe-images --region us-east-1 --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text

# us-east-2
aws ec2 describe-images --region us-east-2 --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text
```

### 4️⃣ — Configure your variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in these key values:

```hcl
key_pair_name        = "my-keypair"
ec2_ami_id           = "ami-xxxxxxxxxxxxxxxxx"   # from step 3
ec2_ami_id_secondary = "ami-xxxxxxxxxxxxxxxxx"   # from step 3
allowed_ssh_cidr     = "YOUR.IP.HERE/32"          # curl https://checkip.amazonaws.com
db_username          = "adminuser"
db_password          = "StrongPassword123!"
```

### 5️⃣ — Deploy 🚀

```bash
terraform init       # Download AWS provider plugin
terraform validate   # Check all syntax
terraform plan       # Preview 73 resources
terraform apply      # Deploy — type: yes  (~20 minutes)
```

### 6️⃣ — Test it works ✅

```bash
# Open your web app
curl http://$(terraform output -raw alb_dns_name)
# → Hello from ip-10-0-x-x.ec2.internal

# See all outputs
terraform output
```

---

<div align="center">

## 🔍 Verification Commands

</div>

```bash
# ── Web Application ────────────────────────────────────────────────────────
curl http://$(terraform output -raw alb_dns_name)
# Expected: Hello from ip-10-0-x-x.ec2.internal

# ── ALB Target Health (both servers must be healthy) ──────────────────────
TG_ARN=$(aws elbv2 describe-target-groups --region us-east-1 \
  --query "TargetGroups[?contains(TargetGroupName,'mystic')].TargetGroupArn" \
  --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --region us-east-1 --output table
# Expected: healthy | healthy

# ── VPC Peering Status ─────────────────────────────────────────────────────
aws ec2 describe-vpc-peering-connections --region us-east-1 \
  --query "VpcPeeringConnections[*].{Status:Status.Code,From:RequesterVpcInfo.CidrBlock,To:AccepterVpcInfo.CidrBlock}" \
  --output table
# Expected: active | 10.0.0.0/24 | 192.168.0.0/24

# ── RDS Status ────────────────────────────────────────────────────────────
aws rds describe-db-instances --region us-east-1 \
  --query "DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}" \
  --output table
# Expected: available

# ── All Resources Created ─────────────────────────────────────────────────
terraform state list | wc -l
# Expected: 73+

# ── SSH via Bastion to Web Server ──────────────────────────────────────────
ssh-add my-keypair.pem
ssh -A ec2-user@$(terraform output -raw bastion_public_ip)
# Inside bastion → hop to private EC2:
# ssh ec2-user@<web-server-private-ip>
```

---

<div align="center">

## 🚦 CI/CD Pipeline

</div>

The included `.github/workflows/terraform.yml` automates your workflow:

```
Pull Request → terraform fmt  →  terraform validate  →  terraform plan
                                                              │
                                                    📝 Posts plan as PR comment
                                                              │
Merge to main ──────────────────────────────────► terraform apply ✅
```

**Add these secrets in GitHub → Settings → Secrets → Actions:**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

---

<div align="center">

## 🛠️ Troubleshooting

</div>

| ❌ Error | ✅ Fix |
|---|---|
| `PendingVerification` on EC2 | New AWS account — wait for verification email (up to 4 hrs) then re-run `terraform apply` |
| `FreeTierRestrictionError` on RDS | Set `backup_retention_period = 0` in `modules/rds/rds.tf` |
| `YOUR.IP.HERE/32 is not valid CIDR` | Run `curl https://checkip.amazonaws.com` → update `allowed_ssh_cidr` in tfvars |
| `Unreadable module directory` | You ran `terraform init` from inside `modules/` — `cd` to the root folder first |
| `InvalidCloudWatchLogsRoleArnException` | CloudTrail IAM role missing — check `modules/logging/logging.tf` |
| Replica error: backups not enabled | Set `backup_retention_period = 1` on primary RDS instance |
| `InvalidKeyPair.NotFound` | Key pair doesn't exist in that region — re-run Step 2 |

---

<div align="center">

## 💰 Cost Estimate

</div>

> ⚠️ **Always run `terraform destroy` when done testing.**

| Resource | Rate | Daily (~24h) |
|---|---|---|
| NAT Gateway × 2 | $0.045/hr + data | ~$2.20 |
| EC2 t3.micro × 5 | $0.0104/hr each | ~$1.25 |
| RDS db.t3.micro | $0.017/hr | ~$0.41 |
| ALB | $0.008/hr + LCUs | ~$0.20 |
| WAF v2 | $5/month flat | ~$0.17 |
| Secrets Manager | $0.40/secret/month | ~$0.01 |
| CloudTrail | First trail free | $0.00 |
| **Total estimate** | | **~$4–6/day** |

---

<div align="center">

## 🔒 Production Hardening Checklist

</div>

Before this setup handles real traffic:

```hcl
# modules/rds/rds.tf — flip these for production
deletion_protection     = true    # prevent accidental drops
skip_final_snapshot     = false   # keep a backup on destroy
multi_az                = true    # automatic failover
backup_retention_period = 7       # 7 days of daily backups

# main.tf — use remote state for team environments
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "mystic-falls/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

| Setting | This Repo | Production |
|---|---|---|
| `deletion_protection` | `false` | `true` |
| `skip_final_snapshot` | `true` | `false` |
| `multi_az` | `false` | `true` |
| `backup_retention_period` | `1` | `7` |
| Terraform state | local `.tfstate` | S3 + DynamoDB lock |
| IAM permissions | `AdministratorAccess` | Least privilege |

---

<div align="center">

## 🧹 Tear Down

</div>

```bash
# Destroys all 73 resources (~10 minutes)
terraform destroy
# type: yes

# Verify no billable resources remain
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter Name=state,Values=available --output table
# Should be empty

aws rds describe-db-instances --region us-east-1 \
  --query "DBInstances[].DBInstanceIdentifier" --output text
# Should be empty
```

---

<div align="center">

## 🔧 Useful Commands

</div>

```bash
# See every resource Terraform manages
terraform state list

# Show a specific resource's details
terraform state show module.rds.aws_db_instance.primary

# Rebuild only one module (without touching others)
terraform destroy -target=module.rds
terraform apply  -target=module.rds

# Format all .tf files
terraform fmt -recursive

# Get your current IP
curl -s https://checkip.amazonaws.com

# Watch all pods / resources apply in real time
terraform apply | tee apply.log
```

---

<div align="center">

## 📖 Full Article

Read the complete step-by-step walkthrough on Medium — every design decision explained, every pitfall documented:

**[🚀 Building a Production-Grade Dual-VPC AWS Architecture from Zero](https://medium.com/@narengl2001)**

---

## 🤝 Contributing

Pull requests welcome! For major changes, open an issue first.

```bash
git checkout -b feature/your-improvement
git commit -m "feat: your improvement"
git push origin feature/your-improvement
# Open a Pull Request on GitHub
```

---

## 📄 License

**LinkedIn** © [Naren](https://www.linkedin.com/in/naren-g-7bb580229/) — Cloud & DevSecOps Engineer

---

<sub>Built with ❤️ | Terraform · AWS · Python · GitHub Actions</sub>

</div>
