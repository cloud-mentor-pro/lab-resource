# /project:rollback

Rollback stack về trạng thái trước khi deploy thất bại.

## Usage
```
/project:rollback stack=[{env}-webapp-{layer}]
```

## Steps

### 1. Kiểm tra trạng thái hiện tại
```bash
aws cloudformation describe-stacks \
  --stack-name {stack-name} \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Stacks[0].{Status:StackStatus,Reason:StackStatusReason}'
```

### 2. Nếu stack đang ở trạng thái ROLLBACK_COMPLETE → không thể recover, phải xóa và tạo lại
### Nếu stack đang ở UPDATE_ROLLBACK_FAILED → dùng continue-rollback

```bash
aws cloudformation continue-update-rollback \
  --stack-name {stack-name} \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 3. Monitor rollback
```bash
aws cloudformation describe-stack-events \
  --stack-name {stack-name} \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'StackEvents[?contains(ResourceStatus, `ROLLBACK`)].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}' \
  --output table
```

## Notes
KHÔNG bao giờ tự ý rollback prod mà không confirm với user.
