# webapp — AWS Infrastructure (CloudFormation)

Learning project: xây dựng hạ tầng web hoàn chỉnh trên AWS bằng CloudFormation — VPC, ALB, EC2, ACM, Route53 — với HTTPS và zero SSH access. Toàn bộ infrastructure được quản lý as code, không tạo resource thủ công.

Điểm đặc biệt: project được tổ chức để làm việc hiệu quả với **Claude Code** — có đầy đủ CLAUDE.md, rules, skills, commands trong thư mục `.claude/`.

---

## Architecture

```
Internet
    │
    ▼
[Route53]  sampleproject.cloudmentor-pro.click  (A record → ALB alias)
    │
    ▼
[ALB]  internet-facing  ·  Public Subnet 1a + 1c
  :80  → redirect 301 → :443
  :443 → forward → Target Group  (ACM cert, TLS 1.3)
    │
    ├──▶ [EC2 web-1a]  Private Subnet 1a  (Amazon Linux 2023, httpd)
    └──▶ [EC2 web-1c]  Private Subnet 1c  (Amazon Linux 2023, httpd)
              │
              ▼
        [NAT Gateway]  →  Internet (package updates)

EC2 access: SSM Session Manager — không cần KeyPair, không cần SSH, không cần Bastion
```

---

## Stack Order

Deploy theo đúng thứ tự — không bỏ bước, không đảo ngược:

```
1. {env}-webapp-networking   →  templates/networking/webapp-networking.yaml
2. {env}-webapp-security     →  templates/security/webapp-security.yaml
3. {env}-webapp-compute      →  templates/compute/webapp-compute.yaml
```

---

## Quick Start

### 1. Lấy Hosted Zone ID

```bash
aws route53 list-hosted-zones \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'HostedZones[?Name==`cloudmentor-pro.click.`].Id' \
  --output text
```

Điền vào `parameters/dev-compute.json` → `HostedZoneId`.

### 2. Validate templates

```bash
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

---

## EC2 Access (SSM — không cần SSH)

```bash
# Lấy instance ID
aws ec2 describe-instances \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --filters "Name=tag:Project,Values=webapp" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,AZ:Placement.AvailabilityZone}' \
  --output table

# Kết nối
aws ssm start-session \
  --target {instance-id} \
  --profile cloudmentor \
  --region ap-northeast-1
```

---

## Teardown

Xóa theo thứ tự ngược lại — compute trước, networking sau:

```bash
aws cloudformation delete-stack --stack-name dev-webapp-compute --profile cloudmentor --region ap-northeast-1
aws cloudformation delete-stack --stack-name dev-webapp-security --profile cloudmentor --region ap-northeast-1
aws cloudformation delete-stack --stack-name dev-webapp-networking --profile cloudmentor --region ap-northeast-1
```

---

## Project Structure

![Project Structure](Diagram.drawio.svg)

```
webapp-infra/
├── templates/
│   ├── networking/webapp-networking.yaml   ← VPC, Subnets, NAT GW, Route Tables
│   ├── security/webapp-security.yaml       ← Security Groups, IAM Role + Instance Profile
│   └── compute/webapp-compute.yaml         ← EC2 x2, ALB, ACM Certificate, Route53
├── parameters/
│   ├── dev-networking.json    ← gitignored
│   ├── dev-security.json      ← gitignored
│   ├── dev-compute.json       ← gitignored (contains HostedZoneId)
│   └── prod-*.json            ← gitignored
├── .claude/
│   ├── CLAUDE.md              ← Project context cho Claude Code
│   ├── CLAUDE.local.md        ← Personal overrides (gitignored)
│   ├── outputs-catalog.md     ← Danh sách CloudFormation exports
│   ├── rules/                 ← cfn-standards, security-guardrails, data-protection
│   ├── skills/                ← new-stack, cross-stack-ref, iam-audit, cost-guard
│   ├── commands/              ← /project:deploy, validate, diff, rollback, drift
│   └── agents/                ← security-auditor, cost-analyzer
├── DEPLOY.md                  ← Hướng dẫn deploy từ đầu đến cuối
└── Diagram.drawio             ← Sơ đồ cấu trúc project
```

---

## Tham khảo

- [DEPLOY.md](DEPLOY.md) — Hướng dẫn chi tiết từng bước
- [.claude/outputs-catalog.md](.claude/outputs-catalog.md) — CloudFormation export names
- [AWS CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
