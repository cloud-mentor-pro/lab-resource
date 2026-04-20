# /project:validate

Validate CloudFormation template — chạy trước khi deploy bất cứ thứ gì.

## Usage
```
/project:validate [layer=networking|security|compute|all]
```

## Steps

### 1. cfn-lint — syntax và best practice
```bash
# Single stack:
cfn-lint templates/{layer}/webapp-{layer}.yaml

# Tất cả stacks:
cfn-lint templates/**/*.yaml
```

### 2. AWS CloudFormation validate-template — syntax check chính thức
```bash
aws cloudformation validate-template \
  --template-body file://templates/{layer}/webapp-{layer}.yaml \
  --profile cloudmentor \
  --region ap-northeast-1
```

### 3. cfn-nag — security scan
```bash
cfn_nag_scan --input-path templates/{layer}/webapp-{layer}.yaml
```

## Kết quả mong muốn
- cfn-lint: 0 ERROR (warning OK)
- validate-template: trả về Parameters list (không có error)
- cfn-nag: 0 FAILURE (warning OK)

## Nếu chưa cài tools
```bash
pip install cfn-lint
gem install cfn-nag
```
