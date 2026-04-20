# Security Guardrails

Những rule này KHÔNG được vi phạm. Claude tự động check khi tạo hoặc sửa template.

---

## IAM

```yaml
# KHÔNG BAO GIỜ dùng wildcard * trong cả Action lẫn Resource cùng lúc
# BAD:
Effect: Allow
Action: '*'
Resource: '*'

# BAD:
Effect: Allow
Action: 's3:*'
Resource: '*'

# GOOD:
Effect: Allow
Action:
  - s3:GetObject
  - s3:PutObject
Resource: !Sub 'arn:aws:s3:::${BucketName}/*'
```

- Không dùng `AdministratorAccess` managed policy trên EC2 role
- Không dùng `NotAction` hoặc `NotResource` trừ khi có lý do rõ ràng
- Mọi EC2 dùng IAM Instance Profile + SSM — không dùng KeyPair

---

## Security Groups

```yaml
# KHÔNG MỞ 0.0.0.0/0 cho port bất kỳ trừ 80 và 443 trên ALB SG
# BAD:
SecurityGroupIngress:
  - IpProtocol: '-1'   # all traffic
    CidrIp: 0.0.0.0/0

# BAD:
SecurityGroupIngress:
  - IpProtocol: tcp
    FromPort: 22        # SSH không bao giờ mở
    CidrIp: 0.0.0.0/0

# GOOD — EC2 SG chỉ nhận traffic từ ALB SG:
SecurityGroupIngress:
  - IpProtocol: tcp
    FromPort: 80
    ToPort: 80
    SourceSecurityGroupId: !Ref SecurityGroupAlb
    Description: HTTP from ALB only
```

---

## S3 (nếu thêm sau)

```yaml
# LUÔN có PublicAccessBlockConfiguration khi tạo S3 bucket:
PublicAccessBlockConfiguration:
  BlockPublicAcls: true
  BlockPublicPolicy: true
  IgnorePublicAcls: true
  RestrictPublicBuckets: true
```

---

## ALB

```yaml
# HTTP :80 phải redirect sang HTTPS, không bao giờ forward thẳng:
AlbListenerHttp:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    Port: 80
    Protocol: HTTP
    DefaultActions:
      - Type: redirect
        RedirectConfig:
          Protocol: HTTPS
          Port: '443'
          StatusCode: HTTP_301   # permanent redirect

# TLS policy cho HTTPS listener:
SslPolicy: ELBSecurityPolicy-TLS13-1-2-2021-06
```

---

## EC2

- Không dùng `MapPublicIpOnLaunch: true` cho private subnets
- Không gán public IP trực tiếp cho EC2 (dùng ALB + private subnet)
- `UserData` không được chứa credentials, secrets, hoặc hardcoded IPs
