# SQL Server Memory Requirements Issue

## ❌ Problem

SQL Server container fails with error:
```
sqlservr: This program requires a machine with at least 2000 megabytes of memory.
```

## 📊 Memory Requirements

| SQL Server Version | Minimum RAM | Recommended RAM |
|-------------------|-------------|-----------------|
| SQL Server 2022   | 2GB (2000MB) | 4GB+ |
| SQL Server 2019   | 2GB (2000MB) | 4GB+ |
| SQL Server 2017   | 2GB (2000MB) | 4GB+ |

## ✅ Solutions

### Solution 1: Upgrade EC2 Instance Type (Recommended)

#### Current Instance Types and Costs

| Instance Type | RAM | vCPUs | Cost/Month (On-Demand) | Best For |
|--------------|-----|-------|------------------------|----------|
| t2.micro     | 1GB | 1     | ~$8                    | ❌ Too small |
| t3.small     | 2GB | 2     | ~$15                   | ✅ Minimum |
| t3.medium    | 4GB | 2     | ~$30                   | ✅✅ Recommended |
| t3.large     | 8GB | 2     | ~$60                   | Production |

#### Steps to Upgrade

**Option A: Via AWS Console**
1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your instance
3. **Instance State** → **Stop Instance** (wait until stopped)
4. **Actions** → **Instance Settings** → **Change Instance Type**
5. Select **t3.medium** (recommended) or **t3.small** (minimum)
6. Click **Apply**
7. **Instance State** → **Start Instance**
8. Wait for instance to start (get new public IP if not using Elastic IP)
9. SSH back in and rerun deployment

**Option B: Via AWS CLI**
```bash
# Stop instance
aws ec2 stop-instances --instance-ids i-YOUR-INSTANCE-ID

# Wait for stopped state
aws ec2 wait instance-stopped --instance-ids i-YOUR-INSTANCE-ID

# Change instance type
aws ec2 modify-instance-attribute \
  --instance-id i-YOUR-INSTANCE-ID \
  --instance-type t3.medium

# Start instance
aws ec2 start-instances --instance-ids i-YOUR-INSTANCE-ID
```

---

### Solution 2: Use SQL Server 2019 (Temporary Workaround)

⚠️ **Note**: Even SQL Server 2019 requires 2GB RAM. This only helps if you're very close to 2GB.

Update `docker-compose.yml`:
```yaml
sqlserver:
  image: mcr.microsoft.com/mssql/server:2019-latest
```

---

### Solution 3: Add Swap Space (Not Recommended)

⚠️ **Warning**: This is slow and not suitable for production!

```bash
# Create 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make it permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

Then try starting containers again:
```bash
cd ~/PRM392_SaleApp
docker-compose up -d
```

---

### Solution 4: Use MySQL/PostgreSQL Instead (Alternative)

If you can't upgrade, consider using MySQL or PostgreSQL which have lower memory requirements.

#### Switch to MySQL

Update `docker-compose.yml`:
```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: salesapp-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE=SalesAppDB
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 3s
      retries: 10

volumes:
  mysql-data:
```

Update `application.yaml`:
```yaml
spring:
  datasource:
    url: jdbc:mysql://mysql:3306/SalesAppDB
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQLDialect
```

---

## 🔍 Check Your Current Instance

```bash
# Check memory
free -h

# Check instance type (from EC2 metadata)
curl http://169.254.169.254/latest/meta-data/instance-type

# Check available memory
cat /proc/meminfo | grep MemTotal
```

---

## ✅ Recommended Action Plan

### For Testing/Development:
1. **Stop your current instance**
2. **Change to t3.small** (2GB RAM - minimum)
3. **Start instance and redeploy**
4. **Cost**: ~$15/month

### For Production:
1. **Stop your current instance**
2. **Change to t3.medium** (4GB RAM - recommended)
3. **Consider Reserved Instance** for 70% savings
4. **Cost**: ~$30/month (on-demand) or ~$10/month (reserved)

---

## 🚀 After Upgrading Instance

```bash
# SSH to your instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check memory
free -h
# Should show at least 2GB

# Go to project directory
cd ~/PRM392_SaleApp

# Pull latest changes (if any)
git pull origin main

# Load environment
source /etc/salesapp/env.sh

# Start services
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

## 💡 Cost Optimization Tips

### Save Money with Reserved Instances
- **1-year term**: Save ~40%
- **3-year term**: Save ~70%
- Best for production workloads

### Use Spot Instances for Dev/Test
- Save up to 90%
- Can be terminated by AWS
- Good for non-critical workloads

### Auto-Stop During Off-Hours
```bash
# Create a cron job to stop instance at night
# Add to crontab -e:
0 22 * * * aws ec2 stop-instances --instance-ids i-YOUR-ID
0 8 * * 1-5 aws ec2 start-instances --instance-ids i-YOUR-ID
```

---

## 📊 Instance Type Comparison

| Instance | RAM | vCPUs | Cost/Month | SQL Server | Spring Boot | Best For |
|----------|-----|-------|------------|------------|-------------|----------|
| t2.micro | 1GB | 1 | $8 | ❌ | ⚠️ | Free tier only |
| t3.small | 2GB | 2 | $15 | ⚠️ Minimum | ✅ | Dev/Test |
| t3.medium | 4GB | 2 | $30 | ✅✅ | ✅✅ | Recommended |
| t3.large | 8GB | 2 | $60 | ✅✅✅ | ✅✅✅ | Production |

---

## 🆘 Still Having Issues?

### Check Docker Resources
```bash
# View Docker stats
docker stats

# Check container status
docker ps -a

# View SQL Server logs
docker logs salesapp-sqlserver
```

### Verify Memory After Changes
```bash
# Total memory
free -h

# Available memory
cat /proc/meminfo | grep MemAvailable

# Swap space
swapon --show
```

---

## 📚 Additional Resources

- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [SQL Server Hardware Requirements](https://learn.microsoft.com/en-us/sql/sql-server/install/hardware-and-software-requirements-for-installing-sql-server)
- [AWS Reserved Instances](https://aws.amazon.com/ec2/pricing/reserved-instances/)

---

**Bottom Line**: For SQL Server, you need at least **t3.small (2GB)**, but **t3.medium (4GB)** is recommended! 🚀
