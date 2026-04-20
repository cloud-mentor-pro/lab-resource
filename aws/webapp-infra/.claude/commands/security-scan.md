# /project:security-scan

Chạy toàn bộ security scan trên templates.

## Usage
```
/project:security-scan [layer=networking|security|compute|all]
```

## Steps

### 1. cfn-nag
```bash
cfn_nag_scan --input-path templates/{layer}/webapp-{layer}.yaml
# Hoặc toàn bộ:
cfn_nag_scan --input-path templates/ --template-pattern '**/*.yaml'
```

### 2. checkov
```bash
checkov -f templates/{layer}/webapp-{layer}.yaml --framework cloudformation
# Hoặc toàn bộ:
checkov -d templates/ --framework cloudformation
```

### 3. Tóm tắt kết quả
Hiển thị:
- Số lượng PASS / FAIL / WARN cho mỗi tool
- Liệt kê các FAIL kèm resource bị ảnh hưởng
- Đề xuất cách fix cho mỗi FAIL

## Ngưỡng chấp nhận
- cfn-nag FAILURE = 0 → phải fix trước khi deploy
- checkov FAILED = 0 → phải fix trước khi deploy prod
- Warning/Skipped → document lý do nếu cố tình bỏ qua
