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
| Multi-region setup | us-east-1 + us-east-2 | Fully automated | Single terraform apply |

</div>

---

<div align="center">

## 🗺️ Architecture

</div>

```
                              👤 Users
                                 │
                    ┌────────────▼────────────┐
                    │    🛡️  AWS WAF v2        │  SQLi · XSS · Rate Limit
                    └────────────┬────────────┘
                                 │
               ┌─────────────────▼──────────────────┐
               │       🌐 Internet Gateway           │
               │              us-east-1              │
               └─────────────────┬──────────────────┘
                                 │
               ┌─────────────────▼──────────────────┐     🔗 VPC Peering     ┌──────────────────────────┐
               │      ⚖️  Application Load Balancer  │◄──────────────────────►│   🏰 Clock Tower VPC     │
               │         HTTP · Health Checks        │    Private Tunnel       │   192.168.0.0/24         │
               └──────────┬──────────────┬───────────┘                        │   us-east-2b             │
                          │              │                                     │                          │
               ┌──────────▼──┐    ┌──────▼──────────┐                        │   🖥️ CT Server 1 (pub)   │
               │ 🖥️ Web Srv 1 │    │  🖥️ Web Server 2 │                       │   🖥️ CT Server 2 (priv)  │
               │  private-1a │    │   private-1b    │                        └──────────────────────────┘
               └──────────┬──┘    └──────┬──────────┘
                          └──────┬───────┘
               ┌─────────────────▼──────────────────┐
               │        🗄️  Amazon RDS MySQL 8.0     │
               │    Primary (1a)  +  Replica (1b)    │
               │    Encrypted · gp3 · Auto-scaling   │
               └────────────────────────────────────┘

  📋 CloudTrail → 🪣 S3 → λ Lambda → 📣 SNS Alerts
  📊 VPC Flow Logs → 👁️ CloudWatch Log Group
  ⚡ DynamoDB  ·  🔐 Secrets Manager  ·  👤 IAM
```

---

<div align="center">

## 📦 What Gets Deployed

</div>

<table>
<tr>
<td>

### 🔒 Security Layer
| Service | Purpose |
|---|---|
| **WAF v2** | Managed rules + rate limit |
| **Security Groups** | ALB → Web → RDS chain |
| **Secrets Manager** | DB credentials |
| **IAM Roles** | Least privilege ×3 |

</td>
<td>

### 🌐 Networking Layer
| Service | Purpose |
|---|---|
| **VPC × 2** | Isolated networks |
| **VPC Peering** | Cross-region tunnel |
| **NAT Gateway** | Private outbound |
| **Internet Gateway** | Public entry |

</td>
</tr>
<tr>
<td>

### ⚙️ Compute Layer
| Service | Count |
|---|---|
| **ALB** | 1 cross-AZ |
| **EC2 Bastion** | 1 jump host |
| **EC2 Web Servers** | 2 private |
| **EC2 Clock Tower** | 2 secondary |

</td>
<td>

### 📊 Observability Layer
| Service | Purpose |
|---|---|
| **CloudTrail** | API audit logs |
| **CloudWatch** | VPC flow logs |
| **S3** | Log storage |
| **Lambda + SNS** | Alerts pipeline |

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
├── 📄 main.tf                          ← Root — wires all modules
├── 📄 variables.tf                     ← All input variables
├── 📄 outputs.tf                       ← Post-deploy endpoints
├── 📄 terraform.tfvars.example         ← Safe template to commit
├── 📄 .gitignore                       ← Keeps secrets out of git
│
├── 📁 .github/workflows/
│   └── 📄 terraform.yml               ← CI/CD: plan on PR, apply on merge
│
└── 📁 modules/
    ├── 📁 vpc/                         ← VPC + IGW + Flow Logs
    ├── 📁 subnets/                     ← 6 subnets + NAT GW + routes
    ├── 📁 security_groups/             ← 5 security groups
    ├── 📁 peering/                     ← Cross-region VPC Peering
    ├── 📁 waf/                         ← WAFv2 Web ACL
    ├── 📁 alb/                         ← ALB + Target Group
    ├── 📁 ec2/                         ← Bastion + Web servers
    ├── 📁 rds/                         ← MySQL 8.0 Primary
    ├── 📁 iam/                         ← IAM Roles (×3)
    ├── 📁 logging/                     ← CloudTrail + S3 + Lambda + SNS
    ├── 📁 dynamodb/                    ← DynamoDB table
    ├── 📁 secrets/                     ← Secrets Manager
    ├── 📁 cloudwatch_alarms/           ← ALB + RDS alarms + dashboard
    ├── 📁 guardduty/                   ← Threat detection
    ├── 📁 elasticache/                 ← Redis cache
    ├── 📁 cloudfront/                  ← CDN
    ├── 📁 asg/                         ← Auto Scaling Group
    ├── 📁 backup/                      ← AWS Backup (RDS)
    ├── 📁 vpc_endpoints/               ← S3 + DynamoDB private endpoints
    └── 📁 costmanagement/              ← Budgets + anomaly detection
```

---

<div align="center">

## ⚡ Quick Start

</div>

### Prerequisites

```bash
# Check Terraform version (needs >= 1.5.0)
terraform --version

# Check AWS CLI
aws --version

# Configure AWS credentials
aws configure
```

### Step 1 — Create EC2 Key Pairs in both regions

```bash
# us-east-1 (Mystic Falls)
aws ec2 create-key-pair --region us-east-1 --key-name my-keypair \
  --query 'KeyMaterial' --output text > my-keypair.pem

# us-east-2 (Clock Tower)
aws ec2 create-key-pair --region us-east-2 --key-name my-keypair \
  --query 'KeyMaterial' --output text > my-keypair-east2.pem

chmod 400 my-keypair.pem my-keypair-east2.pem
```

### Step 2 — Get the latest AMI IDs

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

### Step 3 — Configure your variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
key_pair_name        = "my-keypair"
ec2_ami_id           = "ami-xxxxxxxxxxxxxxxxx"   # from step 2
ec2_ami_id_secondary = "ami-xxxxxxxxxxxxxxxxx"   # from step 2
allowed_ssh_cidr     = "YOUR.IP.HERE/32"          # from: curl https://checkip.amazonaws.com
db_username          = "adminuser"
db_password          = "StrongPassword123!"
alert_email          = "you@example.com"
```

### Step 4 — Deploy 🚀

```bash
terraform init      # Download AWS provider (~30 sec)
terraform validate  # Check syntax
terraform plan      # Preview 73 resources
terraform apply     # Deploy (~20 min) — type: yes
```

### Step 5 — Verify ✅

```bash
# Test your web app
curl http://$(terraform output -raw alb_dns_name)
# → Hello from ip-10-0-x-x.ec2.internal

# Check all outputs
terraform output
```

---

<div align="center">

## 🔍 Verification Commands

</div>

```bash
# ── Web App ───────────────────────────────────────────────────────────────
curl http://$(terraform output -raw alb_dns_name)

# ── ALB Target Health ─────────────────────────────────────────────────────
TG_ARN=$(aws elbv2 describe-target-groups --region us-east-1 \
  --query "TargetGroups[?contains(TargetGroupName,'mystic')].TargetGroupArn" \
  --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --region us-east-1 --output table
# Expected: both targets → healthy

# ── VPC Peering ────────────────────────────────────────────────────────────
aws ec2 describe-vpc-peering-connections --region us-east-1 \
  --query "VpcPeeringConnections[*].{Status:Status.Code,From:RequesterVpcInfo.CidrBlock,To:AccepterVpcInfo.CidrBlock}" \
  --output table
# Expected: active

# ── RDS ────────────────────────────────────────────────────────────────────
aws rds describe-db-instances --region us-east-1 \
  --query "DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}" \
  --output table
# Expected: available

# ── SSH via Bastion ────────────────────────────────────────────────────────
ssh-add my-keypair.pem
ssh -A ec2-user@$(terraform output -raw bastion_public_ip)

# ── All Resources ──────────────────────────────────────────────────────────
terraform state list | wc -l
# Expected: 73+
```

---

<div align="center">

## 🚦 CI/CD Pipeline

</div>

The `.github/workflows/terraform.yml` pipeline automates everything:

```
Pull Request opened
        │
        ▼
  terraform fmt --check    ← fails if formatting is wrong
        │
        ▼
  terraform validate       ← fails if syntax is broken
        │
        ▼
  terraform plan           ← posts full plan as PR comment
        │
        ▼
  Merge to main
        │
        ▼
  terraform apply          ← auto-deploys on merge
```

**Setup secrets in GitHub → Settings → Secrets → Actions:**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

---

<div align="center">

## 💰 Cost Estimate

</div>

> **⚠️ Always run `terraform destroy` when done testing.**

| Resource | Cost |
|---|---|
| NAT Gateway | ~$0.045/hr + $0.045/GB data |
| EC2 t3.micro × 5 | ~$0.052/hr combined |
| RDS db.t3.micro | ~$0.017/hr |
| ALB | ~$0.008/hr + LCU charges |
| WAF v2 | ~$5/month flat |
| CloudTrail | First trail free |
| Secrets Manager | $0.40/secret/month |
| **Total estimate** | **~$8–15/day running 24/7** |

---

<div align="center">

## 🔒 Production Hardening

</div>

Before handling real traffic, update these settings:

```hcl
# modules/rds/rds.tf
deletion_protection     = true    # was false
skip_final_snapshot     = false   # was true
multi_az                = true    # was false — adds ~$0.017/hr
backup_retention_period = 7       # was 1

# main.tf — uncomment the S3 backend
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "mystic-falls/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

---

<div align="center">

## 🧹 Tear Down

</div>

```bash
# Destroys all 73 resources in ~10 minutes
terraform destroy

# Verify nothing billable remains
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter Name=state,Values=available --output table
# Should return empty
```

---

<div align="center">

## 🛠️ Troubleshooting

</div>

| Error | Fix |
|---|---|
| `PendingVerification` on EC2 | New AWS account — wait for email (up to 4 hrs) |
| `FreeTierRestrictionError` on RDS | Set `backup_retention_period = 0` |
| `YOUR.IP.HERE/32 not valid CIDR` | Run `curl https://checkip.amazonaws.com` and update tfvars |
| `Unreadable module directory` | You're in `modules/` — `cd` to root folder first |
| `InvalidCloudWatchLogsRoleArnException` | CloudTrail needs `cloud_watch_logs_role_arn` set |
| Replica error: backups not enabled | Set `backup_retention_period = 1` on primary |

---

<div align="center">

## 📖 Full Walkthrough

Read the complete article explaining every design decision, CIDR choice, and Terraform pattern:

**[🚀 Building a Production-Grade Dual-VPC AWS Architecture from Zero](https://medium.com/@naren)**

*Every step explained. Every pitfall documented. Every line of code included.*

---

## 🤝 Contributing

Pull requests are welcome! For major changes, open an issue first.

```bash
git checkout -b feature/your-feature
git commit -m "feat: your feature description"
git push origin feature/your-feature
# Open a Pull Request
```

---

## 📄 License

MIT © [Naren](https://github.com/your-username)

---

<sub>Built with ❤️ using Terraform · AWS · Python · GitHub Actions</sub>

</div>
