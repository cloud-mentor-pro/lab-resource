# Skill: cross-stack-ref

## Description
Invoke khi user dùng !ImportValue hoặc reference output từ stack khác, hoặc khi
tạo template cần dùng resource từ stack đã có. Keywords trigger: "dùng VPC từ stack",
"lấy subnet từ", "import từ networking", "!ImportValue", "cross-stack", "reference stack".
Cũng invoke khi phát hiện trong template mới có dependency vào stack đã có.

---

## Workflow

### Bước 1 — Tra outputs-catalog.md
Trước khi viết bất kỳ `!ImportValue` nào, tra outputs-catalog.md để lấy đúng export name.

```yaml
# Pattern chuẩn — scalar property:
SomeProperty:
  Fn::ImportValue: !Sub '${NetworkingStackName}-VpcId'

# Pattern chuẩn — list item:
SecurityGroupIds:
  - Fn::ImportValue: !Sub '${SecurityStackName}-SecurityGroupEc2Id'

# Không hardcode tên stack:
# BAD:
SomeProperty: !ImportValue 'dev-webapp-networking-VpcId'

# BAD — !ImportValue !Sub trên cùng 1 dòng là INVALID YAML:
SomeProperty: !ImportValue !Sub '${NetworkingStackName}-VpcId'

# GOOD — dùng Fn::ImportValue: !Sub:
SomeProperty:
  Fn::ImportValue: !Sub '${NetworkingStackName}-VpcId'
```

### Bước 2 — Verify export tồn tại trước khi dùng

```bash
# Kiểm tra export hiện có trên account:
aws cloudformation list-exports \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Exports[?contains(Name, `webapp`)].{Name:Name,Value:Value}' \
  --output table
```

Nếu export chưa tồn tại → nhắc user deploy stack dependency trước.

### Bước 3 — Kiểm tra circular dependency
CloudFormation không cho phép circular import. Kiểm tra:
- networking → không import từ security hoặc compute
- security → chỉ import từ networking
- compute → chỉ import từ networking và security

Nếu phát hiện circular → đề xuất tách resource hoặc dùng SSM Parameter Store thay vì Export.

### Bước 4 — Kiểm tra stack sẽ bị block khi delete
Khi stack A export và stack B import → không thể xóa stack A khi stack B còn tồn tại.
Nhắc user biết dependency này khi teardown.

---

## Export Name Reference (tra nhanh)

```
# Networking exports:
${NetworkingStackName}-VpcId
${NetworkingStackName}-VpcCidr
${NetworkingStackName}-SubnetPublic1aId
${NetworkingStackName}-SubnetPublic1cId
${NetworkingStackName}-SubnetPrivate1aId
${NetworkingStackName}-SubnetPrivate1cId
${NetworkingStackName}-NatGateway1aId

# Security exports:
${SecurityStackName}-SecurityGroupAlbId
${SecurityStackName}-SecurityGroupEc2Id
${SecurityStackName}-IamInstanceProfileEc2Name
${SecurityStackName}-IamRoleEc2SsmArn
```

→ Xem outputs-catalog.md để có danh sách đầy đủ và cập nhật nhất.
