# Deployment Guide — webapp AWS Infrastructure

Hướng dẫn deploy toàn bộ hạ tầng từ đầu, lần đầu tiên.
Kết quả cuối: `https://sampleproject.cloudmentor-pro.click` chạy được.

---

## Mục lục
1. [Prerequisites](#1-prerequisites)
2. [Clone & Setup project](#2-clone--setup-project)
3. [Lấy Hosted Zone ID](#3-lấy-hosted-zone-id)
4. [Điền parameters](#4-điền-parameters)
5. [Validate templates](#5-validate-templates)
6. [Deploy Stack 1 — Networking](#6-deploy-stack-1--networking)
7. [Deploy Stack 2 — Security](#7-deploy-stack-2--security)
8. [Deploy Stack 3 — Compute](#8-deploy-stack-3--compute)
9. [Verify & Test](#9-verify--test)
10. [Access EC2 via SSM](#10-access-ec2-via-ssm)
11. [Teardown](#11-teardown)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites

### Tools cần cài

```bash
# AWS CLI v2
aws --version
# → aws-cli/2.x.x

# cfn-lint (CloudFormation linter)
pip install cfn-lint
cfn-lint --version

# cfn-nag (security scanner) — cần Ruby
gem install cfn-nag
cfn_nag_scan --version
```

### AWS CLI Profile
Profile `cloudmentor` phải được config sẵn:

```bash
# Kiểm tra profile đã có chưa
aws configure list --profile cloudmentor

# Nếu chưa có, setup:
aws configure --profile cloudmentor
# AWS Access Key ID: [nhập key]
# AWS Secret Access Key: [nhập secret]
# Default region name: ap-northeast-1
# Default output format: json
```

### Verify account đúng
```bash
aws sts get-caller-identity --profile cloudmentor
# Kết quả mong đợi:
# {
#   "Account": "<YOUR_ACCOUNT_ID>",
#   "UserId": "...",
#   "Arn": "arn:aws:iam::<YOUR_ACCOUNT_ID>:..."
# }
```

⚠️ **Dừng lại nếu Account không phải `<YOUR_ACCOUNT_ID>`**

---

## 2. Clone & Setup project

```bash
# Clone hoặc giải nén project
unzip webapp-infra.zip
cd webapp-infra

# Kiểm tra cấu trúc
ls -la
# → .claude/  .gitignore  parameters/  README.md  templates/
```

---

## 3. Lấy Hosted Zone ID

Hosted Zone `cloudmentor-pro.click` đã tồn tại — chỉ cần lấy ID.

```bash
aws route53 list-hosted-zones \
  --profile cloudmentor \
  --query 'HostedZones[?Name==`cloudmentor-pro.click.`].{ID:Id,Name:Name}' \
  --output table
```

Kết quả dạng:
```
-------------------------------------------------------
|               ListHostedZones                       |
+--------------------------+--------------------------+
|            ID            |          Name            |
+--------------------------+--------------------------+
|  /hostedzone/Z0123456789 |  cloudmentor-pro.click.  |
+--------------------------+--------------------------+
```

**Lấy phần sau `/hostedzone/`** → ví dụ: `Z0123456789`

---

## 4. Điền parameters

Parameters được tách riêng theo từng stack — chỉ cần điền `HostedZoneId` trong file compute:

```bash
# Mở file parameters/dev-compute.json
# Tìm dòng HostedZoneId — đã có sẵn từ bước 3

code parameters/dev-compute.json
```

Cấu trúc param files hiện tại:
```
parameters/
├── dev-networking.json   ← 6 params (VPC, Subnets)
├── dev-security.json     ← 2 params (Environment, NetworkingStackName)
├── dev-compute.json      ← 7 params (EC2, ALB, Route53, ACM)
├── prod-networking.json
├── prod-security.json
└── prod-compute.json
```

---

## 5. Validate templates

Chạy trước khi deploy bất cứ thứ gì.

```bash
# Validate syntax với AWS
aws cloudformation validate-template \
  --template-body file://templates/networking/webapp-networking.yaml \
  --profile cloudmentor \
  --region ap-northeast-1

aws cloudformation validate-template \
  --template-body file://templates/security/webapp-security.yaml \
  --profile cloudmentor \
  --region ap-northeast-1

aws cloudformation validate-template \
  --template-body file://templates/compute/webapp-compute.yaml \
  --profile cloudmentor \
  --region ap-northeast-1

# Lint tất cả cùng lúc
cfn-lint templates/**/*.yaml
```

✅ Kết quả mong đợi: không có ERROR (warning có thể bỏ qua)

---

## 6. Deploy Stack 1 — Networking

### 6.1 Tạo stack
```bash
aws cloudformation create-stack \
  --stack-name dev-webapp-networking \
  --template-body file://templates/networking/webapp-networking.yaml \
  --parameters file://parameters/dev-networking.json \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 6.2 Chờ stack hoàn thành
```bash
aws cloudformation wait stack-create-complete \
  --stack-name dev-webapp-networking \
  --profile cloudmentor \
  --region ap-northeast-1

echo "✅ Networking stack ready"
```

⏱️ Thời gian: ~3–5 phút (NAT Gateway mất thời gian)

### 6.3 Verify
```bash
aws cloudformation describe-stacks \
  --stack-name dev-webapp-networking \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}' \
  --output json
```

Kết quả mong đợi: `"StackStatus": "CREATE_COMPLETE"` và danh sách Outputs có `VpcId`, `SubnetPublic1aId`, v.v.

---

## 7. Deploy Stack 2 — Security

### 7.1 Tạo stack
```bash
aws cloudformation create-stack \
  --stack-name dev-webapp-security \
  --template-body file://templates/security/webapp-security.yaml \
  --parameters file://parameters/dev-security.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile cloudmentor \
  --region ap-northeast-1
```

> `--capabilities CAPABILITY_NAMED_IAM` bắt buộc vì stack tạo IAM Role với tên cụ thể.

### 7.2 Chờ
```bash
aws cloudformation wait stack-create-complete \
  --stack-name dev-webapp-security \
  --profile cloudmentor \
  --region ap-northeast-1

echo "✅ Security stack ready"
```

⏱️ Thời gian: ~1–2 phút

### 7.3 Verify
```bash
aws cloudformation describe-stacks \
  --stack-name dev-webapp-security \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}' \
  --output json
```

---

## 8. Deploy Stack 3 — Compute

Stack này tạo ACM certificate và validate qua DNS — **mất nhiều thời gian nhất**.

### 8.1 Tạo stack
```bash
aws cloudformation create-stack \
  --stack-name dev-webapp-compute \
  --template-body file://templates/compute/webapp-compute.yaml \
  --parameters file://parameters/dev-compute.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 8.2 Theo dõi tiến trình (quan trọng)
ACM certificate validation có thể mất 5–10 phút. Xem events để biết đang ở bước nào:

```bash
# Chạy lệnh này để xem events theo thời gian thực
watch -n 10 "aws cloudformation describe-stack-events \
  --stack-name dev-webapp-compute \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'StackEvents[*].{Time:Timestamp,Status:ResourceStatus,Resource:LogicalResourceId}' \
  --output table | head -30"
```

Hoặc chờ hoàn toàn:
```bash
aws cloudformation wait stack-create-complete \
  --stack-name dev-webapp-compute \
  --profile cloudmentor \
  --region ap-northeast-1

echo "✅ Compute stack ready"
```

⏱️ Thời gian: ~10–15 phút (ACM certificate validation)

### 8.3 Lấy App URL
```bash
aws cloudformation describe-stacks \
  --stack-name dev-webapp-compute \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`AppUrl`].OutputValue' \
  --output text
```

→ Kết quả: `https://sampleproject.cloudmentor-pro.click`

---

## 9. Verify & Test

### 9.1 Kiểm tra tất cả stacks
```bash
aws cloudformation list-stacks \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --stack-status-filter CREATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `webapp`)].{Name:StackName,Status:StackStatus}' \
  --output table
```

Kết quả mong đợi:
```
---------------------------------------------
|             ListStacks                    |
+---------------------------+---------------+
| Name                      | Status        |
+---------------------------+---------------+
| dev-webapp-networking     | CREATE_COMPLETE|
| dev-webapp-security       | CREATE_COMPLETE|
| dev-webapp-compute        | CREATE_COMPLETE|
+---------------------------+---------------+
```

### 9.2 Test HTTP redirect
```bash
curl -I http://sampleproject.cloudmentor-pro.click
# Kết quả mong đợi:
# HTTP/1.1 301 Moved Permanently
# Location: https://sampleproject.cloudmentor-pro.click/
```

### 9.3 Test HTTPS
```bash
curl -I https://sampleproject.cloudmentor-pro.click
# Kết quả mong đợi:
# HTTP/2 200
```

### 9.4 Mở trên browser
```
https://sampleproject.cloudmentor-pro.click
```

Refresh vài lần → thấy response xen kẽ từ AZ-A và AZ-C (ALB round-robin).

---

## 10. Access EC2 via SSM

Không cần SSH, không cần KeyPair — dùng SSM Session Manager.

### 10.1 Lấy Instance IDs
```bash
aws ec2 describe-instances \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --filters "Name=tag:Project,Values=webapp" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,AZ:Placement.AvailabilityZone}' \
  --output table
```

### 10.2 Connect vào EC2
```bash
# Kết nối vào instance AZ-A
aws ssm start-session \
  --target i-xxxxxxxxxxxxxxxxx \
  --profile cloudmentor \
  --region ap-northeast-1

# Sau khi vào shell:
curl localhost        # test httpd local
systemctl status httpd
cat /var/www/html/index.html
```

> Nếu lỗi `SessionManagerPlugin not found`:
> ```bash
> # macOS:
> brew install --cask session-manager-plugin
> # Linux: xem https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
> ```

---

## 11. Teardown

⚠️ **Xóa theo thứ tự ngược lại** — compute trước, networking sau.
Nếu xóa networking trước khi xóa compute → CloudFormation báo lỗi vì
security stack đang import export từ networking.

```bash
# Bước 1 — Compute (ALB, EC2, Route53, ACM)
aws cloudformation delete-stack \
  --stack-name dev-webapp-compute \
  --profile cloudmentor \
  --region ap-northeast-1

aws cloudformation wait stack-delete-complete \
  --stack-name dev-webapp-compute \
  --profile cloudmentor \
  --region ap-northeast-1
echo "✅ Compute deleted"

# Bước 2 — Security (SG, IAM)
aws cloudformation delete-stack \
  --stack-name dev-webapp-security \
  --profile cloudmentor \
  --region ap-northeast-1

aws cloudformation wait stack-delete-complete \
  --stack-name dev-webapp-security \
  --profile cloudmentor \
  --region ap-northeast-1
echo "✅ Security deleted"

# Bước 3 — Networking (VPC, NAT GW, Subnets...)
aws cloudformation delete-stack \
  --stack-name dev-webapp-networking \
  --profile cloudmentor \
  --region ap-northeast-1

aws cloudformation wait stack-delete-complete \
  --stack-name dev-webapp-networking \
  --profile cloudmentor \
  --region ap-northeast-1
echo "✅ Networking deleted"

echo "🏁 All stacks deleted"
```

> 💡 **Tip tiết kiệm**: Nếu chỉ muốn dừng tốn tiền tạm thời mà không xóa hẳn
> → Stop EC2 instances (tiết kiệm ~$17/tháng) nhưng NAT GW vẫn tính tiền.
> → Muốn tiết kiệm thật sự phải xóa cả stack.

---

## 12. Troubleshooting

### Stack bị ROLLBACK_FAILED
```bash
# Xem lý do thất bại
aws cloudformation describe-stack-events \
  --stack-name dev-webapp-{layer} \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].{Resource:LogicalResourceId,Reason:ResourceStatusReason}' \
  --output table
```

### ACM Certificate bị stuck (không validate được)
Nguyên nhân thường gặp: Hosted Zone ID sai trong parameters/dev-compute.json.
```bash
# Kiểm tra CNAME record đã được tạo chưa
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0123456789 \
  --profile cloudmentor \
  --query 'ResourceRecordSets[?Type==`CNAME`]' \
  --output table
```
Nếu không có CNAME record nào → Hosted Zone ID sai → sửa lại và deploy lại.

### EC2 không healthy trong Target Group
```bash
# Kiểm tra target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names dev-webapp-tg-web \
    --profile cloudmentor \
    --region ap-northeast-1 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text) \
  --profile cloudmentor \
  --region ap-northeast-1
```

Nguyên nhân thường gặp:
- EC2 chưa khởi động xong httpd (chờ thêm 2–3 phút)
- Security Group EC2 không cho phép traffic từ ALB SG

### Export không tìm thấy khi deploy security/compute
```bash
# Liệt kê tất cả exports hiện có
aws cloudformation list-exports \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Exports[?contains(Name, `webapp`)].{Name:Name,Value:Value}' \
  --output table
```
Nếu thiếu export → stack dependency chưa được deploy → deploy stack đó trước.

---

## Tóm tắt thời gian deploy

| Stack | Thời gian | Bước tốn thời gian |
|---|---|---|
| networking | ~5 phút | NAT Gateway |
| security | ~2 phút | IAM Role |
| compute | ~15 phút | ACM certificate DNS validation |
| **Tổng** | **~22 phút** | |
