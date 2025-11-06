# ✅ AWS EC2 Deployment Guide Created!

Your SalesApp is now ready for AWS EC2 deployment without `.env` files!

## 📦 What Was Created

### 📚 Documentation (4 files)
1. ✅ **`AWS_EC2_DEPLOYMENT.md`** - Complete AWS deployment guide
2. ✅ **`EC2_QUICK_START.md`** - Quick start for AWS (⭐ start here)
3. ✅ **`AWS_PARAMETER_STORE_GUIDE.md`** - Secure credential management
4. ✅ **`deploy-ec2.sh`** - Automated deployment script

### 🔄 Updated Files
- ✅ **`README.md`** - Added AWS deployment section

---

## 🚀 Quick Deployment to AWS EC2

### Method 1: Automated Script (Recommended)

```bash
# 1. SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# 2. Download and run deployment script
curl -o deploy-ec2.sh https://raw.githubusercontent.com/L4azy/PRM392_SaleApp/main/deploy-ec2.sh
chmod +x deploy-ec2.sh
./deploy-ec2.sh

# 3. Follow prompts to enter credentials
```

The script will:
- ✅ Install Docker & Docker Compose
- ✅ Clone your repository
- ✅ Prompt for credentials (no .env file needed)
- ✅ Initialize database
- ✅ Start the application
- ✅ Verify deployment

### Method 2: Manual Deployment

Follow the step-by-step guide in **[EC2_QUICK_START.md](EC2_QUICK_START.md)**

---

## 🔐 Three Ways to Manage Secrets (No .env Files)

### 1. Environment Variables (Quick & Simple)
Store credentials in `/etc/salesapp/env.sh`:
```bash
export DB_PASSWORD="YourPassword123"
export SIGNER_KEY="your-jwt-key"
# ... etc
```

**Pros**: Simple, fast setup  
**Cons**: Stored on disk (less secure)  
**Best for**: Development, testing

### 2. AWS Parameter Store (Recommended for Production)
Store secrets in AWS Systems Manager Parameter Store:
```bash
aws ssm put-parameter --name "/salesapp/db-password" --value "Pass123" --type "SecureString"
```

**Pros**: Encrypted, audited, centralized  
**Cons**: Requires IAM setup  
**Best for**: Production, compliance  
**Guide**: [AWS_PARAMETER_STORE_GUIDE.md](AWS_PARAMETER_STORE_GUIDE.md)

### 3. Docker Secrets (Docker Swarm)
For multi-node deployments with Docker Swarm.

**Best for**: Orchestrated deployments

---

## 🎯 Prerequisites for AWS EC2

### EC2 Instance Requirements
- **Instance Type**: `t3.medium` or larger (4GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS or Amazon Linux 2023
- **Storage**: 20GB minimum
- **Region**: Any AWS region

### Security Group Configuration
Open these ports:
- **22** (SSH): Your IP only
- **80** (HTTP): 0.0.0.0/0 (if using Nginx)
- **443** (HTTPS): 0.0.0.0/0 (if using SSL)
- **8080** (API): Your IP or use ALB
- **1433** (SQL Server): BLOCK from internet

---

## 📋 Deployment Checklist

### Before Deployment
- [ ] Create AWS EC2 instance (t3.medium+)
- [ ] Configure Security Group (ports 22, 8080)
- [ ] Generate SSH key pair
- [ ] Optionally: Set up AWS Parameter Store
- [ ] Optionally: Create IAM role for EC2

### During Deployment
- [ ] SSH to EC2 instance
- [ ] Run deployment script OR follow manual steps
- [ ] Enter credentials when prompted
- [ ] Wait for initialization (2-3 minutes)
- [ ] Verify deployment

### After Deployment
- [ ] Test API: `http://your-ec2-ip:8080`
- [ ] Test Swagger: `http://your-ec2-ip:8080/swagger-ui/index.html`
- [ ] Set up Nginx reverse proxy (optional)
- [ ] Configure SSL with Let's Encrypt (optional)
- [ ] Set up CloudWatch monitoring (optional)
- [ ] Configure backup strategy

---

## 🔧 Post-Deployment Setup (Recommended)

### 1. Set Up Nginx Reverse Proxy
```bash
sudo apt install nginx -y
# Configure nginx (see EC2_QUICK_START.md)
```

**Benefits**: Access via port 80, better security, load balancing

### 2. Enable SSL with Let's Encrypt
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

**Benefits**: HTTPS encryption, trust, SEO

### 3. Auto-Start on Boot
```bash
sudo systemctl enable docker
# Service file created by deploy script
sudo systemctl enable salesapp
```

**Benefits**: Application restarts automatically after reboot

### 4. Set Up Monitoring
- CloudWatch for metrics
- CloudWatch Logs for application logs
- SNS for alerts

### 5. Configure Backups
```bash
# Database backups to S3
aws s3 mb s3://salesapp-backups
# Add backup script (see AWS_EC2_DEPLOYMENT.md)
```

---

## 📊 Access Your Application

### Application Access

**Local Testing (from EC2)**
```bash
curl http://localhost:8080/swagger-ui/index.html
```

**Remote Access (from browser)**
```
http://your-ec2-public-ip:8080
http://your-ec2-public-ip:8080/swagger-ui/index.html
```

**With Nginx (after setup)**
```
http://your-ec2-public-ip
http://your-domain.com (with DNS)
https://your-domain.com (with SSL)
```

### Database Access

**From EC2 (CLI)**
```bash
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C
```

**From Your Computer (SSH Tunnel)**
```bash
# Open tunnel
ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip

# Connect with SSMS/Azure Data Studio to: localhost:1433
```

**See**: [DATABASE_ACCESS_GUIDE.md](DATABASE_ACCESS_GUIDE.md) for complete instructions

---

## 🛠️ Common Operations

### View Logs
```bash
docker-compose logs -f
docker-compose logs app --tail=100
```

### Restart Application
```bash
docker-compose restart
# or
sudo systemctl restart salesapp
```

### Update Application
```bash
cd ~/PRM392_SaleApp
git pull origin main
docker-compose up --build -d
```

### Backup Database
```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/backup.bak'"
```

### Stop Application
```bash
docker-compose down
# or
sudo systemctl stop salesapp
```

---

## 🆘 Troubleshooting

### Can't connect to EC2?
- Check Security Group allows your IP on port 22
- Verify SSH key permissions: `chmod 400 your-key.pem`
- Check EC2 instance is running

### Application not starting?
```bash
docker-compose logs app
docker-compose ps
```

### Database issues?
```bash
docker-compose logs sqlserver
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "SELECT name FROM sys.databases"
```

### Can't access from browser?
- Check Security Group allows port 8080
- Verify application is running: `docker-compose ps`
- Check EC2 public IP: `curl http://169.254.169.254/latest/meta-data/public-ipv4`

---

## 💰 Cost Estimation

### Typical Monthly Costs (us-east-1)

**Development/Testing:**
- EC2 t3.medium (on-demand): ~$30/month
- 20GB EBS storage: ~$2/month
- Data transfer: ~$5/month
- **Total: ~$37/month**

**Production (with optimizations):**
- EC2 t3.medium (1-year Reserved): ~$17/month
- 20GB EBS storage: ~$2/month
- Elastic IP: Free (if attached)
- CloudWatch: Free tier covers basic usage
- **Total: ~$19/month**

**Cost Saving Tips:**
- Use Reserved Instances (save up to 70%)
- Use Spot Instances for dev/test (save up to 90%)
- Stop instances when not in use
- Use Auto Scaling based on demand

---

## 🎓 Next Steps

1. **Deploy to EC2**: Follow [EC2_QUICK_START.md](EC2_QUICK_START.md)
2. **Secure your app**: Set up Nginx + SSL
3. **Monitor**: Configure CloudWatch
4. **Backup**: Set up automated backups
5. **Scale**: Consider Auto Scaling Group for production

---

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| **[EC2_QUICK_START.md](EC2_QUICK_START.md)** | ⭐ Start here - Quick AWS deployment |
| **[AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)** | Complete AWS deployment guide |
| **[AWS_PARAMETER_STORE_GUIDE.md](AWS_PARAMETER_STORE_GUIDE.md)** | Secure credential management |
| **[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)** | Local Docker deployment |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues and solutions |

---

## ✨ Key Benefits

### No .env Files
✅ No sensitive data in files  
✅ No risk of committing secrets  
✅ Better security practices  

### Easy Deployment
✅ One script deployment  
✅ Automated setup  
✅ Clear documentation  

### Production Ready
✅ Systemd service for auto-start  
✅ Health checks  
✅ Easy updates  
✅ Monitoring ready  

### Flexible Secret Management
✅ Environment variables  
✅ AWS Parameter Store  
✅ Docker secrets  

---

## 🎉 You're Ready!

Your SalesApp is now configured for secure AWS EC2 deployment without `.env` files!

**Quick Start**: Go to [EC2_QUICK_START.md](EC2_QUICK_START.md) and follow the 3-step deployment process.

**Questions?** Check the [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md) for detailed information.

**Good luck with your deployment! 🚀**

---

**Created**: November 5, 2025  
**For**: AWS EC2 Deployment  
**Security**: No .env files, production-ready
