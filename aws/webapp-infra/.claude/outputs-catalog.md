# Outputs Catalog — webapp

Tham khảo file này khi cần dùng `!ImportValue` trong template.
Format: `!ImportValue '{StackName}-{OutputKey}'`

---

## dev-webapp-networking

| Export Name | Value | Dùng cho |
|---|---|---|
| `dev-webapp-networking-VpcId` | VPC ID | security, compute |
| `dev-webapp-networking-VpcCidr` | 10.0.0.0/16 | security rules |
| `dev-webapp-networking-SubnetPublic1aId` | Public Subnet AZ-A | ALB |
| `dev-webapp-networking-SubnetPublic1cId` | Public Subnet AZ-C | ALB |
| `dev-webapp-networking-SubnetPrivate1aId` | Private Subnet AZ-A | EC2 |
| `dev-webapp-networking-SubnetPrivate1cId` | Private Subnet AZ-C | EC2 |
| `dev-webapp-networking-NatGateway1aId` | NAT GW AZ-A | reference only |

---

## dev-webapp-security

| Export Name | Value | Dùng cho |
|---|---|---|
| `dev-webapp-security-SecurityGroupAlbId` | ALB SG ID | ALB |
| `dev-webapp-security-SecurityGroupEc2Id` | EC2 SG ID | EC2 instances |
| `dev-webapp-security-IamInstanceProfileEc2Name` | EC2 Instance Profile | EC2 IamInstanceProfile |
| `dev-webapp-security-IamRoleEc2SsmArn` | EC2 IAM Role ARN | reference only |

---

## dev-webapp-compute

| Export Name | Value | Dùng cho |
|---|---|---|
| `dev-webapp-compute-AlbDnsName` | ALB DNS hostname | Route53, monitoring |
| `dev-webapp-compute-AppUrl` | https://sampleproject.cloudmentor-pro.click | documentation |
| `dev-webapp-compute-AcmCertificateArn` | ACM cert ARN | reference only |

---

## Prod (future — same pattern with prefix `prod-webapp-`)

Khi deploy prod, export names tự động đổi thành `prod-webapp-{layer}-{OutputKey}`
vì dùng `!Sub '${AWS::StackName}-{OutputKey}'` trong Outputs.
