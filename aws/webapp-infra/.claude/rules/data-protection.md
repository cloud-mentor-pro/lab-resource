# Data Protection

## DeletionPolicy — rule theo environment

```yaml
# dev: không cần retain (tiết kiệm cost khi xóa stack)
# prod: BẮT BUỘC Retain cho mọi stateful resource

# PATTERN cho stateful resource:
MyDatabase:
  Type: AWS::RDS::DBInstance
  DeletionPolicy: !If [IsProd, Retain, Delete]
  UpdateReplacePolicy: !If [IsProd, Retain, Delete]
```

### Stateful resources — BẮT BUỘC có DeletionPolicy khi thêm vào project:
- `AWS::RDS::DBInstance`
- `AWS::RDS::DBCluster`
- `AWS::DynamoDB::Table`
- `AWS::S3::Bucket` (nếu chứa data)
- `AWS::EFS::FileSystem`
- `AWS::ElastiCache::ReplicationGroup`

### Stateless resources — không cần DeletionPolicy:
- EC2, ALB, Security Group, Route Table, Subnet, IGW, NAT GW

---

## UpdateReplacePolicy
Luôn đi kèm với DeletionPolicy — nếu quên, CloudFormation sẽ DELETE resource
cũ trước khi tạo resource mới khi có replacement update.

```yaml
# LUÔN set cả hai cùng nhau:
DeletionPolicy: Retain
UpdateReplacePolicy: Retain
```

---

## Snapshot trước khi delete (prod)
Với RDS và ElastiCache, dùng `Snapshot` thay vì `Retain` nếu muốn giữ data
nhưng không giữ resource:

```yaml
DeletionPolicy: Snapshot    # chỉ hợp lệ với RDS, ElastiCache
UpdateReplacePolicy: Snapshot
```

---

## Lưu ý hiện tại
Project webapp hiện tại (EC2 + ALB) không có stateful resource.
Rules này sẽ áp dụng khi mở rộng thêm RDS, S3, DynamoDB, v.v.
