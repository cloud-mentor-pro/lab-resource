# Skill: iam-audit

## Description
Invoke tự động khi user tạo hoặc chỉnh sửa IAM resource trong bất kỳ template nào.
Trigger khi thấy bất kỳ resource type nào sau: AWS::IAM::Role, AWS::IAM::Policy,
AWS::IAM::ManagedPolicy, AWS::IAM::InstanceProfile, AWS::IAM::User, AWS::IAM::Group.
Keywords: "tạo role", "thêm policy", "IAM permission", "iam role", "assume role".

---

## Audit Checklist — check tất cả, báo cáo từng điểm

### 1. Wildcard check (CRITICAL)
```yaml
# BAD — wildcard Action VÀ Resource cùng lúc:
Statement:
  - Effect: Allow
    Action: '*'
    Resource: '*'

# BAD — wildcard Action trên resource cụ thể:
Statement:
  - Effect: Allow
    Action: 'ec2:*'
    Resource: '*'

# GOOD — specific actions, specific resource:
Statement:
  - Effect: Allow
    Action:
      - ec2:DescribeInstances
      - ec2:StartInstances
    Resource: !Sub 'arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:instance/*'
```
→ Flag mọi trường hợp `Action: '*'` hoặc `Resource: '*'` đi kèm với Action rộng

### 2. AssumeRolePolicyDocument — Principal check
```yaml
# BAD — bất kỳ ai cũng có thể assume:
Principal: '*'

# BAD — cross-account không kiểm soát:
Principal:
  AWS: '*'

# GOOD — chỉ EC2 service:
Principal:
  Service: ec2.amazonaws.com

# GOOD — specific account:
Principal:
  AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
```

### 3. Dangerous actions — cần ghi chú rõ lý do
Những action này cần có comment giải thích tại sao cần:
- `iam:PassRole` — có thể dùng để leo quyền
- `iam:CreateRole` / `iam:AttachRolePolicy` — privilege escalation
- `sts:AssumeRole` với Resource `*`
- `lambda:InvokeFunction` với Resource `*`
- `s3:*` — quá rộng

### 4. AdministratorAccess — không được dùng trên resource không phải người dùng
```yaml
# BAD — EC2 role không cần admin:
ManagedPolicyArns:
  - arn:aws:iam::aws:policy/AdministratorAccess

# GOOD — chỉ đúng policy cần thiết:
ManagedPolicyArns:
  - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

### 5. NotAction / NotResource — luôn cần review
```yaml
# Cần xem xét kỹ — NotAction cho phép tất cả trừ những gì liệt kê:
Statement:
  - Effect: Allow
    NotAction: 'iam:*'
    Resource: '*'
```
→ Báo warning và giải thích rủi ro, hỏi user có thật sự cần không

---

## Output format khi phát hiện vấn đề

```
🔴 CRITICAL — [ResourceLogicalId]: [Mô tả vấn đề]
   → [Đề xuất fix cụ thể]

🟡 WARNING  — [ResourceLogicalId]: [Mô tả vấn đề]
   → [Đề xuất fix hoặc yêu cầu giải thích]

✅ OK       — [ResourceLogicalId]: Không phát hiện vấn đề
```

CRITICAL phải fix trước khi deploy.
WARNING phải có giải thích hoặc fix.
