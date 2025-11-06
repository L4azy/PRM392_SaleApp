# Quick Start: AWS EC2 Deployment

## 🚀 One-Command Deployment

### Prerequisites
- AWS EC2 instance (t3.medium or larger, Ubuntu 22.04)
- SSH access to your EC2 instance
- Security Group: Open ports 22, 8080

### Deploy in 3 Steps

#### 1. Connect to EC2
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### 2. Download and Run Deployment Script
```bash
# Download the deployment script
curl -o deploy-ec2.sh https://raw.githubusercontent.com/L4azy/PRM392_SaleApp/main/deploy-ec2.sh

# Make it executable
chmod +x deploy-ec2.sh

# Run the deployment
./deploy-ec2.sh
```

#### 3. Access Your Application
```
http://3.27.207.79:8080
http://3.27.207.79:8080/swagger-ui/index.html
```

Or simply:
```
http://:8080
http://:8080/swagger-ui/index.html
```

#### 4. Access Your Database
See **[DATABASE_ACCESS_GUIDE.md](DATABASE_ACCESS_GUIDE.md)** for complete database access instructions.

Quick access from EC2:
```bash
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C
```

---

## 🔧 Manual Deployment (Step by Step)

### 1. Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**Log out and log back in**

### 2. Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Clone Repository
```bash
git clone https://github.com/L4azy/PRM392_SaleApp.git
cd PRM392_SaleApp
```

### 4. Set Environment Variables
```bash
# Create secure directory
sudo mkdir -p /etc/salesapp

# Create environment file
sudo nano /etc/salesapp/env.sh
```

Add this content (replace with your values):
```bash
#!/bin/bash
export DB_PASSWORD="YourStrong@Passw0rd123"
export SIGNER_KEY="your-32-character-minimum-jwt-signing-key-here"
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
export GEMINI_API_KEY="your-gemini-api-key"
export CLOUD_NAME="your-cloudinary-cloud-name"
export API_KEY="your-cloudinary-api-key"
export API_SECRET="your-cloudinary-api-secret"
```

Secure the file:
```bash
sudo chmod 600 /etc/salesapp/env.sh
sudo chown ubuntu:ubuntu /etc/salesapp/env.sh

# Load environment variables
source /etc/salesapp/env.sh
```

### 5. Initialize Database
```bash
# Start SQL Server
docker-compose up -d sqlserver

# Wait 60 seconds
sleep 60

# Initialize database
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -i /docker-entrypoint-initdb.d/01-init-database.sql
```

### 6. Start Application
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## 🔒 Security Setup (Production)

### 1. Configure Security Group
Open AWS Console → EC2 → Security Groups:
- Port 22: Your IP only (SSH)
- Port 80: 0.0.0.0/0 (HTTP)
- Port 443: 0.0.0.0/0 (HTTPS)
- Port 8080: Your IP range (or use ALB)
- Port 1433: DENY from internet

### 2. Install Nginx Reverse Proxy
```bash
sudo apt install nginx -y

sudo nano /etc/nginx/sites-available/salesapp
```

Add:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable:
```bash
sudo ln -s /etc/nginx/sites-available/salesapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Now access via: `http://your-ec2-ip` (no port needed)

### 3. Enable SSL (Production)
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

---

## 📊 Common Commands

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Update application (automated script)
~/deploy-salesapp.sh

# Or manual update
cd ~/PRM392_SaleApp
git pull origin main
docker-compose up --build -d

# Backup database
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/backup.bak'"
```

### 🔑 Important Paths
- **Environment file**: `/etc/salesapp/env.sh`
- **Project directory**: `~/PRM392_SaleApp`
- **Update script**: `~/deploy-salesapp.sh`

---

## 🆘 Troubleshooting

### Application not starting?
```bash
docker-compose logs app
```

### Database issues?
```bash
docker-compose logs sqlserver
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases"
```

### Port conflicts?
```bash
sudo netstat -tulpn | grep :8080
sudo systemctl stop nginx  # if using nginx
```

---

## 📚 Full Documentation

For complete details, see [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)

---

**Quick Help**: For issues, check logs with `docker-compose logs -f`
