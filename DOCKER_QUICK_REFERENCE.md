# Docker Commands Quick Reference

## 🚀 Getting Started

```powershell
# First time setup
Copy-Item .env.example .env        # Create environment file
notepad .env                       # Edit with your credentials
docker-compose up --build -d       # Start everything

# Quick start (after first setup)
.\start-docker.ps1                 # PowerShell
# or
start-docker.bat                   # Command Prompt
```

## 🎮 Essential Commands

```powershell
# Start services (background)
docker-compose up -d

# Start services (with logs)
docker-compose up

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Stop and remove everything (including volumes)
docker-compose down -v
```

## 📊 Monitoring

```powershell
# View logs (all services)
docker-compose logs -f

# View logs (specific service)
docker-compose logs -f app
docker-compose logs -f sqlserver

# Check status
docker-compose ps

# Resource usage
docker stats

# Last 50 lines of logs
docker-compose logs --tail=50
```

## 🔨 Building & Rebuilding

```powershell
# Rebuild all services
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Rebuild and start
docker-compose up --build

# Rebuild only app
docker-compose build app
docker-compose up -d app
```

## 🗄️ Database Operations

```powershell
# Connect to SQL Server
docker exec -it salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd"

# Run SQL query directly
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourPassword" -Q "SELECT * FROM SalesAppDB.dbo.Users"

# Backup database
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourPassword" -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/SalesAppDB.bak'"

# Copy backup to host
docker cp salesapp-sqlserver:/var/opt/mssql/backup/SalesAppDB.bak ./SalesAppDB.bak
```

## 🐛 Debugging

```powershell
# Enter container shell
docker exec -it salesapp-backend bash
docker exec -it salesapp-sqlserver bash

# Check environment variables
docker exec salesapp-backend env

# Test connectivity
docker exec salesapp-backend ping sqlserver

# View container details
docker inspect salesapp-backend
docker inspect salesapp-sqlserver

# Check networks
docker network ls
docker network inspect prm392_saleapp_salesapp-network
```

## 🧹 Cleanup

```powershell
# Remove stopped containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# Remove containers, volumes, and images
docker-compose down -v --rmi all

# Clean entire Docker system (CAREFUL!)
docker system prune -a --volumes
```

## 🔄 Updates & Maintenance

```powershell
# Pull latest base images
docker-compose pull

# Update and restart
docker-compose down
docker-compose pull
docker-compose up --build -d

# View image details
docker images

# Remove unused images
docker image prune -a
```

## 🎯 Useful Combinations

```powershell
# Fresh start (preserve data)
docker-compose down
docker-compose up --build

# Complete reset
docker-compose down -v --rmi all
docker-compose up --build

# Update code and restart
docker-compose build app
docker-compose restart app

# Check what changed
docker-compose ps
docker-compose logs --tail=20 app
```

## 🔍 Troubleshooting Commands

```powershell
# Health check
docker-compose ps
curl http://localhost:8080/actuator/health

# Port check
netstat -ano | findstr :8080
netstat -ano | findstr :1433

# Detailed logs with timestamps
docker-compose logs -f -t

# Find errors in logs
docker-compose logs | Select-String "ERROR"
docker-compose logs | Select-String "Exception"

# Container resource usage
docker stats --no-stream

# Check if SQL Server is ready
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourPassword" -Q "SELECT 1"
```

## 🌐 Access URLs

```
Application:     http://localhost:8080
Swagger UI:      http://localhost:8080/swagger-ui.html
API Docs:        http://localhost:8080/v3/api-docs
Health Check:    http://localhost:8080/actuator/health

SQL Server:      localhost:1433
  Username:      sa
  Password:      (from .env file)
  Database:      SalesAppDB
```

## 📝 Configuration Files

```powershell
# Edit environment variables
notepad .env

# Edit compose configuration
notepad docker-compose.yml

# Edit application configuration
notepad SalesApp\src\main\resources\application.yaml

# Edit SQL initialization
notepad init-db\01-init-database.sql
```

## 🎓 Common Workflows

### Deploy Fresh Application
```powershell
Copy-Item .env.example .env
notepad .env
docker-compose up --build -d
docker-compose logs -f
```

### Update Application Code
```powershell
# Make code changes
docker-compose build app
docker-compose restart app
docker-compose logs -f app
```

### Reset Database
```powershell
docker-compose down -v
docker-compose up -d
```

### Export/Import Data
```powershell
# Export
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Pass" -Q "BACKUP DATABASE SalesAppDB TO DISK='/var/opt/mssql/backup/db.bak'"
docker cp salesapp-sqlserver:/var/opt/mssql/backup/db.bak ./backup.bak

# Import
docker cp ./backup.bak salesapp-sqlserver:/var/opt/mssql/backup/db.bak
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Pass" -Q "RESTORE DATABASE SalesAppDB FROM DISK='/var/opt/mssql/backup/db.bak' WITH REPLACE"
```

## 💡 Pro Tips

- Use `-d` flag to run in background (detached mode)
- Use `-f` flag with logs to follow output in real-time
- Use `--tail=N` to limit log output to last N lines
- Use `--no-cache` when dependencies change
- Always backup before `down -v` (removes volumes)
- Check `.env` file when configuration issues occur
- SQL Server takes 30-60s to fully start on first run
- Use `docker-compose.dev.yml` for development features

## 🆘 Emergency Commands

```powershell
# Kill all containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Remove all volumes
docker volume rm $(docker volume ls -q)

# Complete Docker cleanup
docker system prune -a --volumes -f
```

⚠️ **Warning**: Emergency commands affect ALL Docker containers, not just this project!

---

**Quick Help**: `docker-compose --help` | `docker --help`
**Documentation**: See DOCKER_DEPLOYMENT.md for detailed guide
**Troubleshooting**: See TROUBLESHOOTING.md for common issues
