# /project:cost-estimate

Ước tính chi phí hàng tháng của hạ tầng webapp.

## Usage
```
/project:cost-estimate [env=dev|prod]
```

## Chi phí thực tế project này (ap-northeast-1, tham khảo)

### dev environment (hiện tại)
| Resource | Qty | Đơn giá/tháng | Tổng |
|---|---|---|---|
| NAT Gateway | 1 | ~$32 | $32 |
| EC2 t3.micro | 2 | ~$8.5 | $17 |
| ALB | 1 | ~$16 (min) | $16 |
| EIP (khi attached) | 1 | $0 | $0 |
| Data transfer | varies | ~$5 | $5 |
| ACM Certificate | 1 | $0 | $0 |
| Route53 queries | varies | ~$0.5 | $0.5 |
| **Tổng ước tính** | | | **~$70/tháng** |

### prod environment (future, 2 NAT GW)
| Resource | Tổng |
|---|---|
| NAT Gateway x2 | ~$64 |
| EC2 t3.small x2 | ~$34 |
| ALB | ~$16 |
| **Tổng ước tính** | **~$120/tháng** |

## Cost warnings
- NAT Gateway là resource đắt nhất — xóa stack khi không dùng để tiết kiệm
- EC2 tính theo giờ — stop instance khi không dùng dev
- ALB tính theo giờ + LCU

## Lưu ý
Đây là ước tính thủ công. Để có số chính xác:
```bash
# Dùng AWS Pricing Calculator hoặc Cost Explorer sau khi deploy
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["webapp"]}}' \
  --profile cloudmentor
```
