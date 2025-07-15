# **📋 CloudFormation Template - SOA Web Infrastructure**

## **🏗️ Tổng quan**
Template này tạo ra một hệ thống web application infrastructure hoàn chỉnh với Auto Scaling Group, Application Load Balancer và NAT Gateway trên AWS.

---

## 🏗️ Architecture Overview

![Architecture Diagram](./architectture-soa-web-alb-asg.svg)

## **🌐 VPC & Networking Infrastructure**

### **VPC Core**
| Resource | Name | CIDR/Config | Mô tả |
|----------|------|-------------|-------|
| **VPC** | `soa-vpc-web-alb-asg` | `10.3.0.0/16` | Virtual Private Cloud chính |
| **Internet Gateway** | `soa-igw-web` | - | Kết nối VPC với Internet |

### **Subnets (4 subnets trên 2 AZ)**
| Subnet | Name | CIDR | AZ | Type |
|--------|------|------|----|----|
| **Public Subnet 1** | `soa-subnet-web-public-1a` | `10.3.1.0/24` | AZ-1a | Public |
| **Public Subnet 2** | `soa-subnet-web-public-1b` | `10.3.3.0/24` | AZ-1b | Public |
| **Private Subnet 1** | `soa-subnet-web-private-1a` | `10.3.2.0/24` | AZ-1a | Private |
| **Private Subnet 2** | `soa-subnet-web-private-1b` | `10.3.4.0/24` | AZ-1b | Private |

### **NAT Infrastructure**
| Resource | Name | Location | Purpose |
|----------|------|----------|---------|
| **Elastic IP** | `soa-eip-web-nat` | - | Static IP cho NAT Gateway |
| **NAT Gateway** | `soa-nat-web` | Public Subnet 1 | Internet access cho private subnets |

### **Routing**
| Route Table | Name | Routes | Associated Subnets |
|-------------|------|--------|--------------------|
| **Public Route Table** | `soa-rtb-web-public` | `0.0.0.0/0 → IGW` | Public Subnet 1 & 2 |
| **Private Route Table** | `soa-rtb-web-private` | `0.0.0.0/0 → NAT Gateway` | Private Subnet 1 & 2 |

### **VPC Endpoints**
| Endpoint | Type | Service | Cost | Purpose |
|----------|------|---------|------|---------|
| **S3 VPC Endpoint** | Gateway | S3 | **FREE** | Direct S3 access không qua Internet |

---

## **🛡️ Security Layer**

### **Security Groups**
| Security Group | Name | Rules | Purpose |
|----------------|------|-------|---------|
| **ALB Security Group** | `soa-sg-alb-web` | Port 80,443 từ `0.0.0.0/0` | Cho phép HTTP/HTTPS từ Internet |
| **EC2 Security Group** | `soa-sg-web-server` | Port 80 từ ALB SG only | Chỉ nhận traffic từ ALB |

### **IAM Security**
| Resource | Name | Policies | Purpose |
|----------|------|----------|---------|
| **IAM Role** | `soa-role-ec2-web-ssm` | `AmazonSSMManagedInstanceCore` | EC2 access qua Session Manager |
| **Instance Profile** | `soa-instance-profile-ec2-web` | - | Attach IAM role vào EC2 |

---

## **💻 Compute Infrastructure**

### **Launch Template**
| Property | Value | Mô tả |
|----------|-------|-------|
| **Name** | `soa-lt-web-server` | Template cho EC2 instances |
| **AMI** | Latest Amazon Linux 2023 | Tự động lấy từ SSM Parameter |
| **Instance Type** | `t2.micro` (parameter) | Có thể thay đổi qua parameter |
| **Security** | No SSH, chỉ SSM | Secure access only |
| **User Data** | Apache web server | Tự động cài và chạy web server |

### **Auto Scaling Group**
| Property | Value | Mô tả |
|----------|-------|-------|
| **Name** | `soa-asg-web-server` | Auto Scaling Group |
| **Min Size** | 2 | Minimum instances |
| **Max Size** | 3 | Maximum instances |
| **Desired** | 2 | Target instances |
| **Location** | Private Subnets | An toàn, không public IP |
| **Health Check** | ELB | ALB kiểm tra health |

### **Auto Scaling Policy**
| Property | Value | Mô tả |
|----------|-------|-------|
| **Type** | Target Tracking | Tự động scale theo metric |
| **Metric** | CPU Utilization | Monitor CPU usage |
| **Target** | 70% | Scale khi CPU > 70% |

---

## **⚖️ Load Balancing**

### **Application Load Balancer**
| Property | Value | Mô tả |
|----------|-------|-------|
| **Name** | `soa-alb-web` | Internet-facing ALB |
| **Scheme** | Internet-facing | Public access |
| **Subnets** | Public Subnet 1 & 2 | Multi-AZ deployment |
| **Protocol** | HTTP (Port 80) | Web traffic |

### **Target Group**
| Property | Value | Mô tả |
|----------|-------|-------|
| **Name** | `soa-tg-web-server` | Target group cho ASG |
| **Health Check** | HTTP `/` mỗi 30s | Monitor instance health |
| **Thresholds** | 2 healthy, 3 unhealthy | Health check criteria |
| **Deregistration** | 20 seconds | Nhanh chóng remove unhealthy |

---

## **📊 Parameters & Customization**

### **Input Parameters**
| Parameter | Default | Options | Mô tả |
|-----------|---------|---------|-------|
| **KeyName** | Required | Existing Key Pair | EC2 Key Pair (dù không dùng SSH) |
| **InstanceType** | `t2.micro` | `t2.micro`, `t3.medium` | EC2 instance type |
| **ServiceName** | `web` | Custom string | Naming convention prefix |

---

## **📈 Outputs**

### **Exported Values**
| Output | Description | Export Name |
|--------|-------------|-------------|
| **VPC ID** | VPC identifier | `{StackName}-VPC-ID` |
| **ALB DNS Name** | Load balancer endpoint | `{StackName}-ALB-DNS` |
| **ASG Name** | Auto Scaling Group name | `{StackName}-ASG-Name` |
| **Target Group ARN** | Target group identifier | `{StackName}-TG-ARN` |
| **NAT Gateway IP** | Elastic IP của NAT | `{StackName}-NAT-IP` |
| **S3 Endpoint ID** | VPC Endpoint identifier | `{StackName}-S3-Endpoint` |

---

## **🏷️ Tagging Strategy**

Tất cả resources được tag với:
- **Name**: Descriptive name theo naming convention
- **SystemID**: `SOA` (System identifier)

---

## **💰 Cost Optimization Features**

- ✅ **Single NAT Gateway** thay vì 2 (tiết kiệm ~$45/tháng)
- ✅ **S3 VPC Endpoint FREE** (Gateway type)
- ✅ **t2.micro instances** (AWS Free Tier eligible)
- ✅ **Shared Route Tables** (giảm complexity)

---

## **🔐 Security Best Practices**

- ✅ **No SSH access** - chỉ SSM Session Manager
- ✅ **Private subnets** cho EC2 instances
- ✅ **Security Groups** với least privilege
- ✅ **NAT Gateway** cho secure internet access
- ✅ **VPC Endpoints** cho S3 access

---

## **🎯 High Availability Features**

- ✅ **Multi-AZ deployment** (2 Availability Zones)
- ✅ **Auto Scaling** theo CPU utilization
- ✅ **ELB Health Checks** với automatic recovery
- ✅ **Target Group** distribute traffic
- ⚠️ **Single NAT** (trade-off cho cost optimization)

**Đây là một production-ready infrastructure phù hợp cho web applications với cân bằng tốt giữa cost, security và availability!**