# /project:diff

Xem changeset giữa template local và stack đang chạy trên AWS — không deploy.

## Usage
```
/project:diff layer=[networking|security|compute] env=[dev|prod]
```

## Steps

### 1. Tạo changeset (không execute)
```bash
CHANGE_SET_NAME="diff-$(date +%Y%m%d-%H%M%S)"

aws cloudformation create-change-set \
  --stack-name {env}-webapp-{layer} \
  --template-body file://templates/{layer}/webapp-{layer}.yaml \
  --parameters file://parameters/{env}-{layer}.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --change-set-name $CHANGE_SET_NAME \
  --change-set-type UPDATE \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 2. Chờ
```bash
aws cloudformation wait change-set-create-complete \
  --stack-name {env}-webapp-{layer} \
  --change-set-name $CHANGE_SET_NAME \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 3. Hiển thị diff
```bash
aws cloudformation describe-change-set \
  --stack-name {env}-webapp-{layer} \
  --change-set-name $CHANGE_SET_NAME \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'Changes[*].{Action:ResourceChange.Action,Resource:ResourceChange.LogicalResourceId,Type:ResourceChange.ResourceType,Replace:ResourceChange.Replacement,Scope:ResourceChange.Scope}' \
  --output table
```

### 4. Xóa changeset sau khi xem (không deploy)
```bash
aws cloudformation delete-change-set \
  --stack-name {env}-webapp-{layer} \
  --change-set-name $CHANGE_SET_NAME \
  --profile cloudmentor \
  --region ap-northeast-1
```

## Đọc kết quả
- `Add` → resource mới
- `Modify` → resource thay đổi
- `Remove` → resource sẽ bị xóa — **cần review kỹ**
- `Replace: True` → resource sẽ bị xóa và tạo lại — **nguy hiểm với stateful resource**
