# Skill: new-stack

## Description
Invoke khi user yêu cầu tạo CloudFormation template hoặc stack mới cho một
service/component chưa có template. Keywords trigger: "tạo stack", "tạo template",
"thêm service", "new stack", "scaffold", "thêm layer mới", "tạo thêm".

---

## Workflow — thực hiện đúng thứ tự, không bỏ bước

### Bước 1 — Xác định layer
Đọc CLAUDE.md phần Stack Topology. Xác định stack mới thuộc layer nào:
- networking → tài nguyên mạng (VPC, subnet, TGW, VPN)
- security → IAM, Security Group, KMS, WAF
- compute → EC2, ECS, Lambda, ALB, ASG
- data → RDS, DynamoDB, S3, ElastiCache (chưa có trong project này)

### Bước 2 — Xác định dependencies
Trả lời 3 câu hỏi này trước khi viết bất kỳ dòng YAML nào:
1. Stack này cần import output gì từ stack nào? → tra outputs-catalog.md
2. Stack này sẽ export output gì cho stack khác?
3. Thứ tự deploy của stack mới so với các stack hiện có?

### Bước 3 — Generate skeleton đúng pattern

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'webapp - {Layer} layer: {brief description}'

Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, prod]

  NetworkingStackName:           # thêm nếu cần import từ networking
    Type: String
    Description: e.g. dev-webapp-networking

Conditions:
  IsProd: !Equals [!Ref Environment, prod]

Resources:
  # Resources ở đây

Outputs:
  # Tất cả outputs đều phải Export
  OutputKey:
    Value: !Ref ResourceLogicalId
    Export:
      Name: !Sub '${AWS::StackName}-OutputKey'
```

### Bước 4 — Áp dụng tags bắt buộc lên MỌI resource

```yaml
Tags:
  - { Key: Name,        Value: !Sub '${Environment}-webapp-{type}-{desc}' }
  - { Key: Environment, Value: !Ref Environment }
  - { Key: Project,     Value: webapp }
  - { Key: ManagedBy,   Value: CloudFormation }
  - { Key: Layer,       Value: {layer} }
```

### Bước 5 — Check security guardrails
Đọc rules/security-guardrails.md và tự review trước khi trả lời:
- IAM: không wildcard Action+Resource cùng lúc
- SG: không mở 0.0.0.0/0 trừ port 80/443 trên ALB
- S3: PublicAccessBlockConfiguration nếu tạo bucket

### Bước 6 — Check data protection
Nếu có stateful resource (RDS, DynamoDB, S3, EFS, ElastiCache):
Đọc rules/data-protection.md và thêm DeletionPolicy + UpdateReplacePolicy.

### Bước 7 — Tạo parameter entry
Thêm parameter file mới `parameters/dev-{layer}.json` và `parameters/prod-{layer}.json`
cho stack mới (NetworkingStackName, SecurityStackName, v.v.)

### Bước 8 — Cập nhật outputs-catalog.md
Thêm section mới vào outputs-catalog.md với tất cả export names của stack vừa tạo.

---

## Checklist trước khi trả kết quả

- [ ] Description có đủ format `'webapp - {Layer} layer: ...'`
- [ ] Tất cả Outputs đều có Export
- [ ] Tất cả resources đều có đủ 5 tags
- [ ] Logical IDs dùng PascalCase, không có hyphen
- [ ] Import dùng `Fn::ImportValue: !Sub '${StackNameParam}-OutputKey'` (không dùng `!ImportValue !Sub` — INVALID YAML)
- [ ] Security guardrails đã check
- [ ] outputs-catalog.md đã cập nhật
