# /project:drift

Phát hiện drift — so sánh trạng thái thực tế trên AWS với CloudFormation template.

## Usage
```
/project:drift [layer=networking|security|compute|all] [env=dev|prod]
```

## Steps

### 1. Trigger drift detection
```bash
aws cloudformation detect-stack-drift \
  --stack-name {env}-webapp-{layer} \
  --profile cloudmentor \
  --region ap-northeast-1
# → trả về StackDriftDetectionId
```

### 2. Chờ detection hoàn thành
```bash
aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id {detection-id} \
  --profile cloudmentor \
  --region ap-northeast-1
# Lặp cho đến khi DetectionStatus = DETECTION_COMPLETE
```

### 3. Xem kết quả
```bash
aws cloudformation describe-stack-resource-drifts \
  --stack-name {env}-webapp-{layer} \
  --profile cloudmentor \
  --region ap-northeast-1 \
  --query 'StackResourceDrifts[?StackResourceDriftStatus!=`IN_SYNC`].{Resource:LogicalResourceId,Status:StackResourceDriftStatus,Expected:ExpectedProperties,Actual:ActualProperties}' \
  --output json
```

## Đọc kết quả
- `IN_SYNC` → OK
- `MODIFIED` → resource bị thay đổi ngoài CloudFormation
- `DELETED` → resource bị xóa ngoài CloudFormation
- `NOT_CHECKED` → resource type không support drift detection

## Xử lý sau khi phát hiện drift
Không tự ý fix drift — báo cáo kết quả và hỏi user muốn xử lý như thế nào:
1. Import lại vào stack
2. Deploy lại để overwrite
3. Chấp nhận và update template theo thực tế
