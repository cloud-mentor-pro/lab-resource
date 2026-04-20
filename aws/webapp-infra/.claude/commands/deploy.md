# /project:deploy

Deploy một CloudFormation stack qua changeset workflow. Luôn review trước khi apply.

## Usage
```
/project:deploy layer=[networking|security|compute] env=[dev|prod]
```

## Workflow — tuân thủ đúng thứ tự

### Bước 1 — Validate template trước
```bash
cfn-lint templates/{layer}/webapp-{layer}.yaml
```
Dừng lại nếu có lỗi ERROR. Warning có thể tiếp tục.

### Bước 2 — Tạo changeset
```bash
aws cloudformation create-change-set \
  --stack-name {env}-webapp-{layer} \
  --template-body file://templates/{layer}/webapp-{layer}.yaml \
  --parameters file://parameters/{env}-{layer}.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --change-set-name deploy-$(date +%Y%m%d-%H%M%S) \
  --change-set-type CREATE  # hoặc UPDATE nếu stack đã tồn tại
  --profile cloudmentor
```

### Bước 3 — Chờ changeset sẵn sàng
```bash
aws cloudformation wait change-set-create-complete \
  --stack-name {env}-webapp-{layer} \
  --change-set-name {change-set-name} \
  --profile cloudmentor
```

### Bước 4 — Hiển thị changeset để review
```bash
aws cloudformation describe-change-set \
  --stack-name {env}-webapp-{layer} \
  --change-set-name {change-set-name} \
  --profile cloudmentor \
  --query 'Changes[*].{Action:ResourceChange.Action,Resource:ResourceChange.LogicalResourceId,Type:ResourceChange.ResourceType,Replace:ResourceChange.Replacement}' \
  --output table
```

**DỪNG LẠI** — hiển thị changeset cho user và hỏi confirm trước khi tiếp tục.
Đặc biệt cảnh báo nếu có action `Remove` hoặc `Replacement: True`.

### Bước 5 — Execute (chỉ sau khi user confirm)
```bash
aws cloudformation execute-change-set \
  --stack-name {env}-webapp-{layer} \
  --change-set-name {change-set-name} \
  --profile cloudmentor
```

### Bước 6 — Monitor
```bash
aws cloudformation describe-stack-events \
  --stack-name {env}-webapp-{layer} \
  --profile cloudmentor \
  --query 'StackEvents[*].{Time:Timestamp,Status:ResourceStatus,Resource:LogicalResourceId,Reason:ResourceStatusReason}' \
  --output table
```

## Notes
- Không bao giờ deploy compute trước security, hoặc security trước networking
- Với stack mới: dùng `--change-set-type CREATE`
- Với stack đã có: dùng `--change-set-type UPDATE`
