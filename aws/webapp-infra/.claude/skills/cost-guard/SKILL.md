# Skill: cost-guard

## Description
Invoke tự động khi user thêm resource có chi phí đáng kể vào template.
Trigger khi thấy bất kỳ resource type nào trong danh sách dưới đây.
Mục tiêu: đảm bảo user biết chi phí trước khi deploy, không bao giờ để bất ngờ về bill.

---

## Danh sách resource cần cảnh báo

| Resource Type | Chi phí ước tính (ap-northeast-1) | Ghi chú |
|---|---|---|
| `AWS::EC2::NatGateway` | ~$32/tháng/cái + $0.045/GB data | Project này: 1 cái dev, 2 cái prod |
| `AWS::ElasticLoadBalancingV2::LoadBalancer` | ~$16/tháng (min) + LCU | Project này: đã có |
| `AWS::RDS::DBInstance` | ~$25–200+/tháng tùy class | Tính theo giờ |
| `AWS::RDS::DBCluster` | ~$50–300+/tháng | Aurora có minimum |
| `AWS::ElastiCache::ReplicationGroup` | ~$50+/tháng | |
| `AWS::ElastiCache::ServerlessCache` | Pay per use | Có thể đắt nếu traffic cao |
| `AWS::OpenSearchService::Domain` | ~$25+/tháng | |
| `AWS::GlobalAccelerator::Accelerator` | ~$18/tháng fixed + $0.01/GB | |
| `AWS::WAFv2::WebACL` | $5/tháng + $1/rule/tháng | |
| `AWS::MSK::Cluster` | ~$100+/tháng | |
| `AWS::EKS::Cluster` | ~$73/tháng (control plane) | |
| `AWS::EC2::Instance` (large+) | ~$60+/tháng (t3.large) | Cảnh báo nếu > t3.small ở dev |
| `AWS::EC2::EIP` | $3.6/tháng nếu không attached | Tính phí khi không dùng |

---

## Workflow khi trigger

### 1. Xác định resource đắt tiền đang được thêm
Liệt kê tất cả resource trong danh sách trên có trong template/request.

### 2. Hiển thị cost warning

```
💰 COST ALERT — Resource đắt tiền được thêm vào:

  [ResourceLogicalId] — [ResourceType]
  Chi phí ước tính: ~$XX/tháng
  Lý do: [giải thích ngắn]
  
  Tip tiết kiệm: [gợi ý nếu có]
```

### 3. Gợi ý tiết kiệm theo context

**NAT Gateway:**
- Dev: dùng 1 NAT GW duy nhất (đã config trong project này)
- Nếu chỉ cần pull image từ ECR/update package: dùng VPC Endpoint thay NAT GW

**RDS:**
- Dev: dùng `db.t3.micro`, single-AZ, không cần Multi-AZ
- Dev: set `DBInstanceClass` nhỏ nhất có thể
- Cân nhắc Aurora Serverless v2 nếu traffic không đều

**ElastiCache:**
- Dev: dùng `cache.t3.micro`, single node (không cluster mode)
- Cân nhắc ElastiCache Serverless cho dev

**EC2:**
- Dev không dùng instance > t3.small trừ khi có lý do rõ ràng

### 4. Hỏi confirm trước khi tiếp tục
Sau khi hiển thị cost alert, hỏi:
"Bạn đã biết chi phí này. Tiếp tục tạo template không?"
