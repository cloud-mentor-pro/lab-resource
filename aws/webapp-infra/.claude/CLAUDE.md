# webapp — AWS Infrastructure Project

## Project Overview
Learning project: VPC + ALB + EC2 with HTTPS on AWS ap-northeast-1 (Tokyo).
All infrastructure managed by CloudFormation. No manual resource creation.

---

## Stack Topology
Deploy in this exact order — never skip, never reverse:

```
1. {env}-webapp-networking   →  templates/networking/webapp-networking.yaml
2. {env}-webapp-security     →  templates/security/webapp-security.yaml
3. {env}-webapp-compute      →  templates/compute/webapp-compute.yaml
```

Dependencies:
- `security` imports VpcId from `networking`
- `compute` imports subnets + SG + IAM profile from `networking` + `security`

Cross-stack references → always use `!ImportValue`. See outputs-catalog.md for all export names.

---

## Technology Decisions
These are final. Do not change without explicit discussion.

| Concern | Decision |
|---|---|
| Web server | EC2 (Amazon Linux 2023) + Apache httpd |
| EC2 access | SSM Session Manager — **no KeyPair, no SSH, no Bastion** |
| Load balancer | ALB internet-facing, HTTPS only |
| HTTP traffic | :80 → 301 redirect to :443 (never forward HTTP) |
| SSL | ACM certificate, DNS validation via Route53 |
| NAT Gateway | dev: 1 (cost saving) / prod: 2 per region (HA) |
| Parameters | Separate file per environment in parameters/ |

---

## Environments

| | dev | prod |
|---|---|---|
| Account ID | <YOUR_ACCOUNT_ID> | (future) |
| AWS CLI profile | `cloudmentor` | (future) |
| Stack prefix | `dev-webapp-` | `prod-webapp-` |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Instance type | t3.micro | t3.small |
| NAT Gateway | 1 | 2 (HA) |
| Parameter files | dev-networking/security/compute.json | prod-networking/security/compute.json |

---

## Domain & Certificate

| | Value |
|---|---|
| Root domain | cloudmentor-pro.click |
| Dev subdomain | sampleproject.cloudmentor-pro.click |
| Hosted Zone | Already exists in account <YOUR_ACCOUNT_ID> |
| Hosted Zone ID | → see parameters/dev-compute.json (HostedZoneId) |

---

## Naming Convention

**Resource tag Name:** `{env}-{project}-{resource_type}-{description}`
```
dev-webapp-vpc-main
dev-webapp-sg-alb
dev-webapp-ec2-web-1a
dev-webapp-alb-main
dev-webapp-nat-1a
```

**Stack names:** `{env}-{project}-{layer}`
```
dev-webapp-networking
dev-webapp-security
dev-webapp-compute
```

**CloudFormation Export names:** `{StackName}-{OutputKey}`
```
dev-webapp-networking-VpcId
dev-webapp-security-SecurityGroupAlbId
dev-webapp-compute-AppUrl
```

**Logical IDs in templates:** `{ResourceType}{Description}`
```
VpcMain
SubnetPublic1a
SecurityGroupAlb
Ec2WebServer1a
AlbListenerHttps
```

---

## Required Tags — every resource must have all 5

```yaml
- { Key: Name,        Value: '{env}-webapp-{type}-{desc}' }
- { Key: Environment, Value: dev | prod }
- { Key: Project,     Value: webapp }
- { Key: ManagedBy,   Value: CloudFormation }
- { Key: Layer,       Value: networking | security | compute }
```

---

## Parameter File Pattern — always use this structure

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, prod]

  NetworkingStackName:          # import từ stack khác bằng tên
    Type: String
    Description: e.g. dev-webapp-networking
```

## Output + Export Pattern — always export every output

```yaml
Outputs:
  VpcId:
    Value: !Ref VpcMain
    Export:
      Name: !Sub '${AWS::StackName}-VpcId'
```

## Cross-stack Import Pattern

```yaml
# Scalar property:
VpcId:
  Fn::ImportValue: !Sub '${NetworkingStackName}-VpcId'

# List item:
SecurityGroupIds:
  - Fn::ImportValue: !Sub '${SecurityStackName}-SecurityGroupEc2Id'
```

---

## Key Files
- `outputs-catalog.md` — all export names by stack
- `parameters/dev-networking.json` — dev networking params (gitignored)
- `parameters/dev-security.json` — dev security params (gitignored)
- `parameters/dev-compute.json` — dev compute params, includes HostedZoneId (gitignored)
- `parameters/prod-{layer}.json` — prod equivalents (gitignored)
- `CLAUDE.local.md` — personal overrides (gitignored)
