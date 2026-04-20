# webapp — AWS Infrastructure (CloudFormation)

VPC + ALB + EC2 với HTTPS, được quản lý hoàn toàn bằng CloudFormation.

## Architecture

```
Internet
    │
    ▼
[Route53] sampleproject.cloudmentor-pro.click
    │
    ▼
[ALB] internet-facing (Public Subnet 1a + 1c)
  :80  → redirect 301 → :443
  :443 → forward → Target Group (ACM cert)
    │
    ├──▶ [EC2 web-1a] Private Subnet 1a (httpd, SSM access)
    └──▶ [EC2 web-1c] Private Subnet 1c (httpd, SSM access)
              │
              ▼
         [NAT Gateway] → Internet (yum update, etc.)
```

## Stack Order — deploy theo thứ tự này

```
1. dev-webapp-networking   → templates/networking/webapp-networking.yaml
2. dev-webapp-security     → templates/security/webapp-security.yaml
3. dev-webapp-compute      → templates/compute/webapp-compute.yaml
```

## Quick Start

### 1. Setup Hosted Zone ID
```bash
# Lấy Hosted Zone ID
aws route53 list-hosted-zones --profile cloudmentor \
  --query 'HostedZones[?Name==`cloudmentor-pro.click.`].Id' \
  --output text

# Điền vào parameters/dev.json → HostedZoneId
```

### 2. Validate templates
```bash
# Trong Claude Code:
/project:validate all
```

### 3. Deploy từng stack
```bash
/project:deploy layer=networking env=dev
/project:deploy layer=security env=dev
/project:deploy layer=compute env=dev
```

### 4. Truy cập
```
https://sampleproject.cloudmentor-pro.click
```

## EC2 Access (SSM — không cần SSH)
```bash
aws ssm start-session \
  --target {instance-id} \
  --profile cloudmentor
```

## Teardown
```bash
# Xóa theo thứ tự ngược lại — compute trước, networking sau
aws cloudformation delete-stack --stack-name dev-webapp-compute --profile cloudmentor
aws cloudformation delete-stack --stack-name dev-webapp-security --profile cloudmentor
aws cloudformation delete-stack --stack-name dev-webapp-networking --profile cloudmentor
```

## Project Structure
```
webapp-infra/
├── templates/
│   ├── networking/webapp-networking.yaml
│   ├── security/webapp-security.yaml
│   └── compute/webapp-compute.yaml
├── parameters/
│   ├── dev.json          ← gitignored
│   └── prod.json         ← gitignored
└── .claude/
    ├── CLAUDE.md
    ├── CLAUDE.local.md   ← gitignored
    ├── settings.json
    ├── outputs-catalog.md
    ├── rules/
    ├── commands/
    ├── skills/
    └── agents/
```
