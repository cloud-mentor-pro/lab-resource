# Environment Separation

## Nguyên tắc cốt lõi
Dev và prod chạy trên **account riêng biệt** — không phân biệt bằng prefix trong cùng account.

---

## Cách xử lý sự khác biệt giữa env

### Dùng Conditions — ĐÚNG cách:
```yaml
Conditions:
  IsProd: !Equals [!Ref Environment, prod]

# NAT GW HA chỉ ở prod:
NatGateway1c:
  Type: AWS::EC2::NatGateway
  Condition: IsProd

# Route private 1c trỏ đúng NAT GW:
NatGatewayId: !If [IsProd, !Ref NatGateway1c, !Ref NatGateway1a]
```

### Dùng parameter file — cho giá trị khác nhau:
```
parameters/dev.json  → InstanceType: t3.micro,  VpcCidr: 10.0.0.0/16
parameters/prod.json → InstanceType: t3.small,  VpcCidr: 10.1.0.0/16
```

### KHÔNG làm — lồng If quá 3 cấp:
```yaml
# BAD — khó đọc, khó debug:
Value: !If [IsProd, !If [IsAsia, 'r6g.large', 't3.large'], t3.micro]
```
Nếu cần logic phức tạp → tách thành parameter riêng trong parameter file.

---

## VPC CIDR không overlap giữa environments

| Environment | VPC CIDR |
|---|---|
| dev | 10.0.0.0/16 |
| prod | 10.1.0.0/16 |

Lý do: tránh conflict khi sau này setup VPC Peering hoặc Transit Gateway.

---

## Stack names không collision

```
dev-webapp-networking   ← dev account
prod-webapp-networking  ← prod account (separate account, same name OK)
```

Vì khác account nên tên stack có thể giống nhau — không cần thêm suffix account.

---

## Deploy command phải chỉ định profile
```bash
# dev:
aws cloudformation ... --profile cloudmentor

# prod (future):
aws cloudformation ... --profile cloudmentor-prod
```

Claude phải luôn hỏi confirm environment trước khi chạy lệnh deploy.
