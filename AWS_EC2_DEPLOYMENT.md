# AWS EC2 Deployment Guide for SalesApp

This guide explains how to deploy your SalesApp with Docker on AWS EC2 without using `.env` files.

## 📋 Prerequisites

1. **AWS Account** with EC2 access
2. **EC2 Instance** requirements:
   - Instance Type: `t3.medium` or larger (minimum 4GB RAM for SQL Server)
   - OS: Ubuntu 22.04 LTS or Amazon Linux 2023
   - Storage: At least 20GB
   - Security Group: Open ports 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (API)

## 🚀 Deployment Methods

### Method 1: Using AWS Systems Manager Parameter Store (Recommended)

This is the most secure method for production environments.

#### Step 1: Store Secrets in AWS Parameter Store

```bash
# Install AWS CLI (if not already installed)
aws configure

# Store parameters (replace with your actual values)
aws ssm put-parameter --name "/salesapp/db-password" --value "YourStrong@Passw0rd123" --type "SecureString"
aws ssm put-parameter --name "/salesapp/signer-key" --value "your-32-character-minimum-jwt-signing-key-here" --type "SecureString"
aws ssm put-parameter --name "/salesapp/gemini-api-key" --value "your-gemini-api-key" --type "SecureString"
aws ssm put-parameter --name "/salesapp/cloudinary-cloud-name" --value "your-cloud-name" --type "String"
aws ssm put-parameter --name "/salesapp/cloudinary-api-key" --value "your-api-key" --type "String"
aws ssm put-parameter --name "/salesapp/cloudinary-api-secret" --value "your-api-secret" --type "SecureString"
```

#### Step 2: Create IAM Role for EC2

1. Go to IAM Console → Roles → Create Role
2. Select "AWS Service" → "EC2"
3. Attach policy: `AmazonSSMReadOnlyAccess`
4. Name it: `SalesApp-EC2-Role`
5. Attach this role to your EC2 instance

#### Step 3: Deploy on EC2

See the deployment script below.

---

### Method 2: Using Environment Variables Directly (Quick Setup)

This method sets environment variables directly on the EC2 instance.

---

## 🔧 EC2 Setup Steps

### 1. Connect to Your EC2 Instance

```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
# or for Amazon Linux
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

### 2. Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version

# Log out and log back in for group changes to take effect
exit
```

### 3. Clone Your Repository

```bash
# Reconnect to EC2
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Install git if not present
sudo apt install git -y

# Clone your repository
git clone https://github.com/L4azy/PRM392_SaleApp.git
cd PRM392_SaleApp
```

### 4. Set Environment Variables

**Option A: Using AWS Parameter Store (Recommended)**

```bash
# Install AWS CLI
sudo apt install awscli -y

# Fetch parameters and export as environment variables
export DB_PASSWORD=$(aws ssm get-parameter --name "/salesapp/db-password" --with-decryption --query "Parameter.Value" --output text)
export SIGNER_KEY=$(aws ssm get-parameter --name "/salesapp/signer-key" --with-decryption --query "Parameter.Value" --output text)
export GEMINI_API_KEY=$(aws ssm get-parameter --name "/salesapp/gemini-api-key" --with-decryption --query "Parameter.Value" --output text)
export CLOUD_NAME=$(aws ssm get-parameter --name "/salesapp/cloudinary-cloud-name" --query "Parameter.Value" --output text)
export API_KEY=$(aws ssm get-parameter --name "/salesapp/cloudinary-api-key" --query "Parameter.Value" --output text)
export API_SECRET=$(aws ssm get-parameter --name "/salesapp/cloudinary-api-secret" --with-decryption --query "Parameter.Value" --output text)
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
```

**Option B: Set Manually (For Testing)**

```bash
export DB_PASSWORD="YourStrong@Passw0rd123"
export SIGNER_KEY="your-32-character-minimum-jwt-signing-key-here"
export GEMINI_API_KEY="your-gemini-api-key"
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
export CLOUD_NAME="your-cloudinary-cloud-name"
export API_KEY="your-cloudinary-api-key"
export API_SECRET="your-cloudinary-api-secret"
```

**Option C: Create a Secure Script (Persistent)**

```bash
# Create a secure environment file (not in git)
sudo nano /etc/salesapp/env.sh
```

Add this content:
```bash
#!/bin/bash
export DB_PASSWORD="YourStrong@Passw0rd123"
export SIGNER_KEY="your-32-character-minimum-jwt-signing-key-here"
export GEMINI_API_KEY="your-gemini-api-key"
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
export CLOUD_NAME="your-cloudinary-cloud-name"
export API_KEY="your-cloudinary-api-key"
export API_SECRET="your-cloudinary-api-secret"
```

Then:
```bash
# Secure the file
sudo chmod 600 /etc/salesapp/env.sh
sudo chown ubuntu:ubuntu /etc/salesapp/env.sh

# Source it
source /etc/salesapp/env.sh
```

### 5. Initialize Database Manually (First Time Only)

```bash
# Start only SQL Server first
docker-compose up -d sqlserver

# Wait for SQL Server to be ready (30-60 seconds)
sleep 60

# Run database initialization
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -i /docker-entrypoint-initdb.d/01-init-database.sql

# Verify database created
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases WHERE name = 'SalesAppDB'"
```

### 6. Start the Application

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## 🔒 Security Best Practices

### 1. Configure Security Group

Allow only necessary ports:
```
- Port 22: Your IP only (SSH)
- Port 80: 0.0.0.0/0 (HTTP) - if using reverse proxy
- Port 443: 0.0.0.0/0 (HTTPS) - if using reverse proxy
- Port 8080: Your application IP range or use ALB
- Port 1433: Blocked from internet (internal only)
```

### 2. Use Nginx as Reverse Proxy (Recommended)

```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/salesapp
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain or IP

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and restart:
```bash
sudo ln -s /etc/nginx/sites-available/salesapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Enable SSL with Let's Encrypt (Production)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com

# Auto-renewal is configured automatically
```

---

## 🔄 Automated Deployment Script

Create a deployment script for easy updates:

```bash
# Create deployment script
nano ~/deploy-salesapp.sh
```

Add this content:
```bash
#!/bin/bash

echo "==================================="
echo "  SalesApp Deployment Script"
echo "==================================="

# Load environment variables
source /etc/salesapp/env.sh

# Navigate to project directory
cd /home/ubuntu/PRM392_SaleApp

# Pull latest changes
echo "Pulling latest code..."
git pull origin main

# Stop current containers
echo "Stopping containers..."
docker-compose down

# Rebuild and start
echo "Building and starting containers..."
docker-compose up --build -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check status
echo "Checking status..."
docker-compose ps

# Show recent logs
echo "Recent logs:"
docker-compose logs --tail=20

echo "==================================="
echo "  Deployment Complete!"
echo "==================================="
```

Make it executable:
```bash
chmod +x ~/deploy-salesapp.sh
```

---

## 🔧 Systemd Service (Auto-start on Boot)

Create a systemd service to start Docker Compose automatically:

```bash
sudo nano /etc/systemd/system/salesapp.service
```

Add this content:
```ini
[Unit]
Description=SalesApp Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/PRM392_SaleApp
EnvironmentFile=/etc/salesapp/env.sh
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable salesapp
sudo systemctl start salesapp
sudo systemctl status salesapp
```

---

## 📊 Monitoring and Maintenance

### View Logs
```bash
# All logs
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f sqlserver

# Last 100 lines
docker-compose logs --tail=100
```

### Check Resource Usage
```bash
docker stats
```

### Backup Database
```bash
# Create backup
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/SalesAppDB.bak'"

# Copy backup to EC2
docker cp salesapp-sqlserver:/var/opt/mssql/backup/SalesAppDB.bak ./backup-$(date +%Y%m%d).bak

# Upload to S3 (optional)
aws s3 cp ./backup-$(date +%Y%m%d).bak s3://your-backup-bucket/salesapp/
```

### Update Application
```bash
# Use the deployment script
~/deploy-salesapp.sh
```

---

## 🆘 Troubleshooting

### Check if services are running
```bash
docker-compose ps
```

### Check logs for errors
```bash
docker-compose logs app | grep -i error
docker-compose logs sqlserver | grep -i error
```

### Restart services
```bash
docker-compose restart
```

### Complete reset (careful - deletes data!)
```bash
docker-compose down -v
docker-compose up --build -d
```

---

## 💰 Cost Optimization

1. **Use Reserved Instances** for production (save up to 70%)
2. **Auto-scaling**: Use AWS Auto Scaling Group if traffic varies
3. **Spot Instances**: For development/testing (save up to 90%)
4. **Elastic IP**: Assign an Elastic IP to avoid IP changes
5. **CloudWatch**: Set up alarms for high CPU/memory usage

---

## 🎯 Production Checklist

- [ ] EC2 instance type: t3.medium or larger
- [ ] Security Group configured (limited ports)
- [ ] IAM Role attached for Parameter Store
- [ ] Environment variables set (no .env file)
- [ ] Database initialized
- [ ] Nginx reverse proxy configured
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] Systemd service enabled
- [ ] Backup strategy configured
- [ ] CloudWatch monitoring enabled
- [ ] Elastic IP assigned
- [ ] DNS configured (Route 53 or external)

---

## 📚 Additional Resources

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Docker on AWS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)

---

**Deployment Date**: November 5, 2025  
**Last Updated**: November 5, 2025
