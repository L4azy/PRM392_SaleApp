# Docker Configuration Summary for SalesApp

## 📁 Files Created/Modified

### New Files Created:
1. **`docker-compose.yml`** - Main orchestration file for SQL Server and Spring Boot app
2. **`.env.example`** - Template for environment variables
3. **`init-db/01-init-database.sql`** - SQL Server database initialization script
4. **`init-db/entrypoint.sh`** - Database initialization helper
5. **`SalesApp/.dockerignore`** - Files to exclude from Docker build
6. **`DOCKER_DEPLOYMENT.md`** - Comprehensive deployment guide
7. **`.gitignore`** - Git ignore rules for Docker files
8. **`start-docker.bat`** - Quick start script for Windows CMD
9. **`start-docker.ps1`** - Quick start script for PowerShell
10. **`docker-compose.dev.yml`** - Development override configuration

### Modified Files:
1. **`SalesApp/pom.xml`** - Added SQL Server JDBC driver
2. **`SalesApp/Dockerfile`** - Updated to use Java 17 and simplified paths
3. **`SalesApp/src/main/resources/application.yaml`** - Configured for SQL Server
4. **`README.md`** - Added Docker deployment instructions

## 🎯 Key Features

### 1. Multi-Container Setup
- **SQL Server 2022**: Latest Microsoft SQL Server with Developer edition
- **Spring Boot App**: Your application running on Java 17
- Automatic network configuration between containers
- Health checks to ensure proper startup order

### 2. Database Initialization
- Automatic database creation on first run
- All tables created from your SQL script
- Idempotent scripts (safe to run multiple times)
- Includes the `CartItemsSnapshot` column

### 3. Environment Configuration
- Centralized environment variables in `.env` file
- Support for multiple environments (dev/prod)
- Secure credential management
- All external APIs configurable

### 4. Developer Experience
- One-command deployment
- Quick start scripts for Windows
- Hot reload support (with dev configuration)
- Remote debugging enabled (port 5005)
- Comprehensive documentation

## 🚀 Quick Start Commands

```powershell
# 1. Setup environment
Copy-Item .env.example .env
# Edit .env with your credentials

# 2. Start everything
docker-compose up --build -d

# 3. Check status
docker-compose ps

# 4. View logs
docker-compose logs -f

# 5. Stop everything
docker-compose down
```

## 🔑 Environment Variables Required

```env
# Database (Required)
DB_PASSWORD=YourStrong@Passw0rd

# JWT (Required)
SIGNER_KEY=your-32-character-minimum-key

# Optional - Gemini AI
GEMINI_API_URL=https://...
GEMINI_API_KEY=your-key

# Optional - Cloudinary
CLOUD_NAME=your-cloud
API_KEY=your-key
API_SECRET=your-secret
```

## 📊 Service Details

### SQL Server Container
- **Image**: mcr.microsoft.com/mssql/server:2022-latest
- **Port**: 1433
- **Username**: sa
- **Password**: From .env file
- **Database**: SalesAppDB
- **Volume**: Persistent storage for data

### Spring Boot Container
- **Base Image**: Eclipse Temurin 17
- **Port**: 8080
- **Build**: Multi-stage Docker build
- **Dependencies**: Maven managed
- **Health Check**: Waits for SQL Server

## 🛠️ Database Schema

Tables created automatically:
- Users
- Categories
- Products
- Carts
- CartItems
- Orders (with CartItemsSnapshot)
- Payments
- Notifications
- ChatMessages
- StoreLocations

## 🔄 Development Workflow

### Making Code Changes
```powershell
# Rebuild only the app
docker-compose up --build app

# Or stop, rebuild, and start
docker-compose down
docker-compose up --build
```

### Database Changes
```powershell
# Modify init-db/01-init-database.sql
# Remove volumes and restart
docker-compose down -v
docker-compose up --build
```

### Debugging
```powershell
# Use dev configuration
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Connect debugger to localhost:5005
```

## 🏥 Health Checks

The setup includes:
- SQL Server health check (10s intervals)
- App dependency on healthy database
- Automatic restart on failure

## 📦 Data Persistence

- SQL Server data persists in named volume `sqlserver-data`
- Data survives container restarts
- To reset completely: `docker-compose down -v`

## 🔐 Security Considerations

### Development:
- ✅ Uses environment variables
- ✅ .env file in .gitignore
- ✅ Separate .env.example template
- ⚠️ Trust server certificate enabled (for SSL)

### Production (Recommended):
- Use Docker secrets or orchestration secrets
- Enable SSL/TLS for SQL Server
- Use non-sa SQL Server user
- Implement proper network segmentation
- Add rate limiting and WAF

## 📈 Resource Requirements

Minimum:
- **RAM**: 4GB (2GB for SQL Server + 1GB for app + 1GB for system)
- **Disk**: 5GB free space
- **CPU**: 2 cores recommended

## 🐛 Troubleshooting

### SQL Server Won't Start
```powershell
# Check password requirements (8+ chars, uppercase, lowercase, numbers, symbols)
# View logs
docker-compose logs sqlserver
```

### App Can't Connect
```powershell
# Verify SQL Server is healthy
docker-compose ps

# Check connection string in logs
docker-compose logs app | Select-String "jdbc"
```

### Port Conflicts
```powershell
# Find what's using the port
netstat -ano | findstr :8080
netstat -ano | findstr :1433

# Change port in docker-compose.yml
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [SQL Server in Docker](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [Spring Boot Docker Guide](https://spring.io/guides/topicals/spring-boot-docker/)

## ✅ Verification Checklist

After deployment:
- [ ] Both containers running: `docker-compose ps`
- [ ] Database accessible: Connect via SSMS/Azure Data Studio
- [ ] API accessible: Visit http://localhost:8080
- [ ] Swagger UI works: Visit http://localhost:8080/swagger-ui.html
- [ ] Logs show no errors: `docker-compose logs`
- [ ] Database tables created: Check in SQL client

## 🎓 Next Steps

1. **Configure your .env file** with real credentials
2. **Run the deployment**: `.\start-docker.ps1` or `start-docker.bat`
3. **Test the API** via Swagger UI
4. **Check the database** using SQL Server client
5. **Review logs** for any issues
6. **Read DOCKER_DEPLOYMENT.md** for advanced topics

## 💡 Tips

- Keep your .env file secure and never commit it
- Use docker-compose.dev.yml for development
- Backup your database regularly
- Monitor container resource usage
- Update base images periodically for security patches

---

**Created**: November 5, 2025
**Docker Compose Version**: 3.8
**SQL Server Version**: 2022
**Java Version**: 17
**Spring Boot Version**: 3.2.1
