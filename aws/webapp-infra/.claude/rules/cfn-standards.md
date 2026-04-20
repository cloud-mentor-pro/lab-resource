# CloudFormation Standards

## Stack Naming
`{env}-{project}-{layer}` → dev-webapp-networking

## Logical ID Convention
`{ResourceType}{Description}` — PascalCase, no hyphens
```
VpcMain            SecurityGroupAlb      Ec2WebServer1a
SubnetPublic1a     IamRoleEc2Ssm         AlbListenerHttps
NatGateway1a       IamInstanceProfileEc2  Route53RecordAlb
```

## Parameter Block Pattern
Mọi stack phải có `Environment` và stack reference params:

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, prod]

  NetworkingStackName:
    Type: String
    Description: e.g. dev-webapp-networking
```

## Output + Export Pattern — BẮT BUỘC export tất cả Outputs

```yaml
Outputs:
  VpcId:
    Value: !Ref VpcMain
    Export:
      Name: !Sub '${AWS::StackName}-VpcId'
```

## Cross-stack Import Pattern

```yaml
# Scalar property:
VpcId:
  Fn::ImportValue: !Sub '${NetworkingStackName}-VpcId'

# List item:
SecurityGroupIds:
  - Fn::ImportValue: !Sub '${SecurityStackName}-SecurityGroupEc2Id'
```
Luôn dùng `NetworkingStackName` parameter, không hardcode tên stack.
`!ImportValue !Sub '...'` trên cùng 1 dòng là INVALID YAML — dùng `Fn::ImportValue: !Sub` thay thế.

## Conditions Pattern

```yaml
Conditions:
  IsProd: !Equals [!Ref Environment, prod]
  IsNotDev: !Not [!Equals [!Ref Environment, dev]]

# Dùng condition:
NatGateway1c:
  Type: AWS::EC2::NatGateway
  Condition: IsProd
```

## Tag Block Pattern (viết tắt YAML, nhất quán toàn project)

```yaml
Tags:
  - { Key: Name,        Value: !Sub '${Environment}-webapp-{type}-{desc}' }
  - { Key: Environment, Value: !Ref Environment }
  - { Key: Project,     Value: webapp }
  - { Key: ManagedBy,   Value: CloudFormation }
  - { Key: Layer,       Value: networking }   # hoặc security | compute
```

## Resources không hỗ trợ Tags — KHÔNG được thêm Tags property

Các resource sau sẽ báo lỗi `E3002 Additional properties are not allowed` nếu thêm Tags:

| Resource Type | Lý do |
|---|---|
| `AWS::IAM::InstanceProfile` | AWS không support Tags trên resource này |
| `AWS::ElasticLoadBalancingV2::Listener` | AWS không support Tags trên Listener |
| `AWS::EC2::VPCGatewayAttachment` | Không có Tags property |
| `AWS::EC2::Route` | Không có Tags property |
| `AWS::EC2::SubnetRouteTableAssociation` | Không có Tags property |
| `AWS::Route53::RecordSet` | Không có Tags property |

Khi tạo resource mới, kiểm tra cfn-lint ngay — `E3002` là dấu hiệu resource không hỗ trợ property đó.

## Security Group Rule Description — ký tự hợp lệ

`Description` trong `SecurityGroupIngress` / `SecurityGroupEgress` chỉ chấp nhận:
```
a-zA-Z0-9. _-:/()#,@[]+=&;{}!$*
```

❌ **KHÔNG dùng**: em-dash `—`, smart quotes, hoặc ký tự Unicode ngoài danh sách trên.
✅ **Dùng**: hyphen `-` thay cho em-dash `—`.

Lỗi khi vi phạm: `Invalid rule description` — AWS API reject, stack → `CREATE_FAILED`.

## DependsOn — chỉ dùng khi cần thiết
CloudFormation tự xử lý dependency qua Ref/GetAtt.
Chỉ dùng DependsOn khi dependency không đi qua Ref/GetAtt (vd: VpcGatewayAttachment → Route).

## Description — mỗi template phải có
```yaml
Description: 'webapp - {Layer} layer: {brief description}'
```
