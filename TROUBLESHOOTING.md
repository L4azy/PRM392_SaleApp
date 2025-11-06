# Docker Deployment Troubleshooting Guide

## 🔍 Quick Diagnostic Commands

```powershell
# Check if Docker is running
docker --version
docker-compose --version

# Check running containers
docker-compose ps

# View all logs
docker-compose logs

# View specific service logs
docker-compose logs sqlserver
docker-compose logs app

# Check container resource usage
docker stats

# Inspect network
docker network ls
docker network inspect prm392_saleapp_salesapp-network
```

## ❌ Common Issues and Solutions

### Issue 1: "Cannot connect to Docker daemon"

**Symptoms:**
```
error during connect: This error may indicate that the docker daemon is not running
```

**Solutions:**
1. Start Docker Desktop
2. Wait for Docker to fully start (check system tray icon)
3. Restart Docker Desktop if needed

---

### Issue 2: SQL Server Password Requirement Error

**Symptoms:**
```
ERROR: The SA_PASSWORD environment variable must follow password policy
```

**Solution:**
Update password in `.env` file to meet requirements:
- Minimum 8 characters
- Contains uppercase letters
- Contains lowercase letters
- Contains numbers
- Contains special characters

Example: `YourStrong@Passw0rd123`

---

### Issue 3: Port Already in Use

**Symptoms:**
```
Error starting userland proxy: listen tcp 0.0.0.0:8080: bind: address already in use
```

**Solutions:**

**Option A: Find and stop the conflicting process**
```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

**Option B: Change the port in docker-compose.yml**
```yaml
services:
  app:
    ports:
      - "8081:8080"  # Change host port to 8081
```

---

### Issue 4: SQL Server Container Keeps Restarting

**Symptoms:**
```
sqlserver-1 | SQL Server exited with code 1
```

**Solutions:**

1. **Check available memory (SQL Server needs 2GB minimum)**
   ```powershell
   docker stats
   ```
   If low on memory, close other applications or increase Docker memory limit in Docker Desktop settings.

2. **Check logs for specific error**
   ```powershell
   docker-compose logs sqlserver
   ```

3. **Remove volume and restart**
   ```powershell
   docker-compose down -v
   docker-compose up --build
   ```

---

### Issue 5: Application Can't Connect to Database

**Symptoms:**
```
Connection refused: connect
com.microsoft.sqlserver.jdbc.SQLServerException
```

**Solutions:**

1. **Verify SQL Server is healthy**
   ```powershell
   docker-compose ps
   # sqlserver should show "healthy"
   ```

2. **Check connection string in .env**
   ```env
   DB_URL=jdbc:sqlserver://sqlserver:1433;databaseName=SalesAppDB;encrypt=true;trustServerCertificate=true
   DB_USERNAME=sa
   DB_PASSWORD=YourStrong@Passw0rd
   ```

3. **Wait longer for SQL Server to be ready**
   SQL Server can take 30-60 seconds to fully start on first run.

4. **Check if database was created**
   ```powershell
   docker exec -it salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -Q "SELECT name FROM sys.databases"
   ```

---

### Issue 6: Maven Build Fails in Docker

**Symptoms:**
```
Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
```

**Solutions:**

1. **Clean local Maven cache**
   ```powershell
   docker-compose down
   docker-compose build --no-cache app
   docker-compose up
   ```

2. **Check Java version in Dockerfile matches pom.xml**
   - Dockerfile uses Java 17
   - pom.xml should specify Java 17

3. **Verify pom.xml syntax**
   ```powershell
   cd SalesApp
   mvn validate
   ```

---

### Issue 7: Database Tables Not Created

**Symptoms:**
- Application starts but tables are missing
- Errors about missing tables in logs

**Solutions:**

1. **Check if init script ran**
   ```powershell
   docker-compose logs sqlserver | Select-String "initialization"
   ```

2. **Manually verify database**
   ```powershell
   docker exec -it salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd"
   
   # In sqlcmd:
   USE SalesAppDB;
   GO
   SELECT name FROM sys.tables;
   GO
   ```

3. **Force recreation**
   ```powershell
   docker-compose down -v
   docker-compose up --build
   ```

---

### Issue 8: Environment Variables Not Loading

**Symptoms:**
- Application fails with "Environment variable not set"
- NULL values for configurations

**Solutions:**

1. **Verify .env file exists**
   ```powershell
   Test-Path .env
   # Should return True
   ```

2. **Check .env file format** (no spaces around =)
   ```env
   # Correct:
   DB_PASSWORD=YourPassword

   # Incorrect:
   DB_PASSWORD = YourPassword
   ```

3. **Restart containers after .env changes**
   ```powershell
   docker-compose down
   docker-compose up -d
   ```

---

### Issue 9: Swagger UI Shows 404

**Symptoms:**
- http://localhost:8080/swagger-ui.html returns 404

**Solutions:**

1. **Try alternative Swagger URL**
   - http://localhost:8080/swagger-ui/index.html
   - http://localhost:8080/swagger-ui/

2. **Check if application started successfully**
   ```powershell
   docker-compose logs app | Select-String "Started"
   ```

3. **Verify OpenAPI configuration**
   ```powershell
   curl http://localhost:8080/v3/api-docs
   ```

---

### Issue 10: Changes Not Reflected After Rebuild

**Symptoms:**
- Code changes don't appear in running application

**Solutions:**

1. **Full rebuild without cache**
   ```powershell
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

2. **Remove all Docker artifacts**
   ```powershell
   docker-compose down -v --rmi all
   docker-compose up --build
   ```

3. **Check .dockerignore isn't excluding important files**

---

## 🧪 Verification Steps

### 1. Basic Connectivity Test
```powershell
# Test SQL Server
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -Q "SELECT @@VERSION"

# Test Application
curl http://localhost:8080/actuator/health
# Or visit in browser
```

### 2. Database Connection Test
```powershell
# Check if app can connect to DB
docker-compose logs app | Select-String "HikariPool"
# Should see "HikariPool-1 - Start completed"
```

### 3. Full System Check
```powershell
# All should be "Up" and "healthy"
docker-compose ps

# No error messages
docker-compose logs | Select-String "ERROR"

# Swagger accessible
Start-Process "http://localhost:8080/swagger-ui.html"
```

---

## 🔧 Advanced Debugging

### Enable Verbose Logging

**Add to docker-compose.yml under app service:**
```yaml
environment:
  - LOGGING_LEVEL_ROOT=DEBUG
  - LOGGING_LEVEL_COM_SALESAPP=DEBUG
  - SPRING_JPA_SHOW_SQL=true
```

### Connect to Container Shell

```powershell
# Spring Boot container
docker exec -it salesapp-backend bash

# SQL Server container
docker exec -it salesapp-sqlserver bash
```

### Check Container Network
```powershell
# Verify containers are on same network
docker network inspect prm392_saleapp_salesapp-network

# Test connectivity between containers
docker exec salesapp-backend ping sqlserver
```

### Monitor Resource Usage
```powershell
# Real-time stats
docker stats

# Container processes
docker top salesapp-backend
docker top salesapp-sqlserver
```

---

## 🆘 Complete Reset

If all else fails, perform a complete reset:

```powershell
# 1. Stop everything
docker-compose down -v --rmi all

# 2. Clean Docker system (optional - removes all unused Docker data)
docker system prune -a --volumes
# WARNING: This affects all Docker containers, not just this project

# 3. Remove .env and recreate
Remove-Item .env
Copy-Item .env.example .env
# Edit .env with correct values

# 4. Fresh start
docker-compose up --build
```

---

## 📞 Getting Help

### Check These First:
1. ✅ Docker Desktop is running
2. ✅ .env file exists and has correct values
3. ✅ Ports 8080 and 1433 are available
4. ✅ At least 4GB RAM available
5. ✅ Internet connection for downloading images

### Collect Information for Support:
```powershell
# System info
docker --version
docker-compose --version

# Container status
docker-compose ps

# Recent logs
docker-compose logs --tail=100 > docker-logs.txt

# Environment check (remove sensitive data before sharing!)
Get-Content .env
```

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [SQL Server on Docker](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-deployment)
- [Spring Boot Docker Guide](https://spring.io/guides/topicals/spring-boot-docker/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

---

**Last Updated**: November 5, 2025
