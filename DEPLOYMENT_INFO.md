# 🚀 SalesApp Deployment Information

## 🌐 Access URLs

### Production Instance
- **Server IP**: `3.27.207.79`
- **API Base URL**: `http://3.27.207.79:8080`
- **Swagger UI**: `http://3.27.207.79:8080/swagger-ui/index.html`
- **Health Check**: `http://3.27.207.79:8080/actuator/health`

### Quick Access (from anywhere)
```
http://:8080
http://:8080/swagger-ui/index.html
```

---

## 🔐 SSH Access

### Connect to Server
```bash
ssh -i "D:\SE183854\FPT_Fall_25\PRM392\SaleApp.pem" ubuntu@3.27.207.79
```

### Key Location
- **Local**: `D:\SE183854\FPT_Fall_25\PRM392\SaleApp.pem`
- **User**: `ubuntu`

---

## ⚙️ Server Configuration

### AWS Details
- **Instance Type**: t3.medium (4GB RAM, 2 vCPUs)
- **Region**: ap-southeast-2 (Sydney)
- **OS**: Ubuntu 22.04 LTS
- **Docker Version**: Latest
- **Docker Compose Version**: Latest

### Environment Configuration
- **Environment File**: `/etc/salesapp/env.sh`
- **Project Directory**: `~/PRM392_SaleApp`
- **Update Script**: `~/deploy-salesapp.sh`

---

## 🛠️ Useful Commands

### Service Management
```bash
# View real-time logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f sqlserver

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart app

# Stop all services
docker-compose down

# Stop and remove volumes (clean restart)
docker-compose down -v
```

### Deployment & Updates
```bash
# Quick update (automated)
~/deploy-salesapp.sh

# Manual update
cd ~/PRM392_SaleApp
git pull origin main
docker-compose up --build -d

# Full rebuild
cd ~/PRM392_SaleApp
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Database Access
```bash
# Access SQL Server CLI
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C

# List databases
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases"

# Backup database
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/backup.bak'"
```

### System Monitoring
```bash
# Check container status
docker-compose ps

# Check system resources
docker stats

# Check memory usage
free -h

# Check disk usage
df -h

# Check network ports
sudo netstat -tulpn | grep -E ':(8080|1433)'
```

### Environment Variables
```bash
# Load environment variables
source /etc/salesapp/env.sh

# View environment variables (be careful - shows secrets!)
env | grep -E 'DB_PASSWORD|SIGNER_KEY|GEMINI|CLOUD'

# Edit environment variables
sudo nano /etc/salesapp/env.sh
```

---

## 🐛 Troubleshooting

### Application Not Starting
```bash
# Check logs
docker-compose logs app

# Check if port is in use
sudo netstat -tulpn | grep :8080

# Restart container
docker-compose restart app
```

### Database Connection Issues
```bash
# Check SQL Server logs
docker-compose logs sqlserver

# Check if SQL Server is ready
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT @@VERSION"

# Verify database exists
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases WHERE name = 'SalesAppDB'"
```

### Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Check SQL Server memory
docker exec salesapp-sqlserver cat /proc/meminfo | grep MemTotal
```

### Container Issues
```bash
# Remove and recreate containers
docker-compose down
docker-compose up -d

# Clean restart (removes data!)
docker-compose down -v
docker-compose up -d
```

---

## 📦 Database Schema

### Tables Created
1. **Users** - User accounts and authentication
2. **Categories** - Product categories
3. **Products** - Product catalog
4. **Carts** - Shopping carts
5. **CartItems** - Items in shopping carts
6. **Orders** - Order records
7. **Payments** - Payment transactions
8. **Notifications** - User notifications
9. **ChatMessages** - Chat messages
10. **StoreLocations** - Physical store locations
11. **Gemini** (AI training data)

---

## 🔄 Update Workflow

### For Code Changes
1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

2. **Deploy to EC2**
   ```bash
   ssh -i "D:\SE183854\FPT_Fall_25\PRM392\SaleApp.pem" ubuntu@13.236.136.19
   ~/deploy-salesapp.sh
   ```

### For Database Changes
1. **Update SQL Script**: `init-db/01-init-database.sql`
2. **Backup Current Database**
3. **Apply Changes**:
   ```bash
   docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -i /path/to/changes.sql
   ```

---

## 📊 Monitoring

### Health Check Endpoints
- **Application**: `http://3.27.207.79:8080/actuator/health`
- **Database**: Check via SQL Server CLI

### Log Locations
- **Application Logs**: `docker-compose logs app`
- **SQL Server Logs**: `docker-compose logs sqlserver`
- **System Logs**: `/var/log/syslog`

### Performance Monitoring
```bash
# Real-time container stats
docker stats

# Application metrics
curl http://localhost:8080/actuator/metrics

# Database connections
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT COUNT(*) FROM sys.dm_exec_connections"
```

---

## 🔒 Security Notes

### Ports Exposed
- **22**: SSH (restricted to your IP)
- **8080**: Application API
- **1433**: SQL Server (Docker internal only)

### Credentials Stored In
- **Environment Variables**: `/etc/salesapp/env.sh` (secured with 600 permissions)
- **Docker Compose**: Reads from environment variables

### Security Best Practices
✅ Environment file secured with 600 permissions  
✅ Database password is strong  
✅ SQL Server not exposed to internet  
✅ SSH key-based authentication  
⚠️ Consider adding Nginx reverse proxy  
⚠️ Consider adding SSL certificate  
⚠️ Consider restricting port 8080 to specific IPs  

---

## 📞 Quick Reference

| What | Command/URL |
|------|-------------|
| **SSH Connect** | `ssh -i "D:\SE183854\FPT_Fall_25\PRM392\SaleApp.pem" ubuntu@3.27.207.79` |
| **API URL** | `http://3.27.207.79:8080` |
| **Swagger** | `http://3.27.207.79:8080/swagger-ui/index.html` |
| **View Logs** | `docker-compose logs -f` |
| **Restart** | `docker-compose restart` |
| **Update** | `~/deploy-salesapp.sh` |
| **Database CLI** | `docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C` |

---

## 📚 Documentation Files

- **[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)** - Local Docker setup
- **[AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)** - Complete EC2 deployment guide
- **[EC2_QUICK_START.md](EC2_QUICK_START.md)** - Quick start guide
- **[DATABASE_ACCESS_GUIDE.md](DATABASE_ACCESS_GUIDE.md)** - Database access methods
- **[FIX_MEMORY_ISSUE.md](FIX_MEMORY_ISSUE.md)** - Memory troubleshooting
- **[EC2_DEPLOYMENT_NO_ENV.md](EC2_DEPLOYMENT_NO_ENV.md)** - Secure deployment without .env files

---

**Last Updated**: November 5, 2025  
**Deployment Status**: ✅ Active and Running
