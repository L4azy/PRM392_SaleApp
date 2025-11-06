# Docker Deployment Guide for SalesApp

This guide explains how to deploy the SalesApp project using Docker with SQL Server.

## Prerequisites

- Docker Desktop installed
- Docker Compose installed
- At least 4GB of free RAM (SQL Server requirement)

## Project Structure

```
PRM392_SaleApp/
├── docker-compose.yml          # Docker orchestration file
├── .env.example               # Environment variables template
├── init-db/                   # Database initialization scripts
│   └── 01-init-database.sql   # SQL Server schema creation
└── SalesApp/
    ├── Dockerfile             # Application container definition
    └── src/                   # Spring Boot source code
```

## Setup Instructions

### 1. Configure Environment Variables

Copy the example environment file and update with your values:

```powershell
Copy-Item .env.example .env
```

Edit the `.env` file with your actual credentials:

```env
# Database Configuration
DB_PASSWORD=YourStrong@Passw0rd

# JWT Configuration (must be at least 32 characters)
SIGNER_KEY=your-signer-key-here-at-least-32-characters-long-for-jwt-security

# Gemini AI Configuration
GEMINI_API_URL=https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent
GEMINI_API_KEY=your-gemini-api-key-here

# Cloudinary Configuration
CLOUD_NAME=your-cloudinary-cloud-name
API_KEY=your-cloudinary-api-key
API_SECRET=your-cloudinary-api-secret
```

### 2. Build and Run

From the root directory (`PRM392_SaleApp`), run:

```powershell
# Build and start all services
docker-compose up --build

# Or run in detached mode (background)
docker-compose up --build -d
```

### 3. Verify Deployment

Check if services are running:

```powershell
docker-compose ps
```

You should see:
- `salesapp-sqlserver` (SQL Server) - Running on port 1433
- `salesapp-backend` (Spring Boot App) - Running on port 8080

### 4. Access the Application

- **API Base URL**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **SQL Server**: localhost:1433 (username: sa, password: from .env file)

## Common Commands

### Start Services
```powershell
docker-compose up -d
```

### Stop Services
```powershell
docker-compose down
```

### View Logs
```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f sqlserver
```

### Restart Services
```powershell
docker-compose restart
```

### Rebuild After Code Changes
```powershell
docker-compose up --build app
```

### Stop and Remove All (including volumes)
```powershell
docker-compose down -v
```

## Database Management

### Connect to SQL Server

Using SQL Server Management Studio (SSMS) or Azure Data Studio:
- **Server**: localhost,1433
- **Authentication**: SQL Server Authentication
- **Username**: sa
- **Password**: (from your .env file)
- **Database**: SalesAppDB

### Execute SQL Scripts Manually

```powershell
# Access SQL Server container
docker exec -it salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd"

# Then run SQL commands
USE SalesAppDB;
GO
SELECT * FROM Users;
GO
```

### Backup Database

```powershell
docker exec salesapp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/SalesAppDB.bak'"
```

## Troubleshooting

### SQL Server Won't Start

**Issue**: Container exits immediately
**Solution**: Ensure your password meets SQL Server requirements:
- At least 8 characters
- Contains uppercase, lowercase, numbers, and symbols

### Application Can't Connect to Database

**Issue**: Connection refused or timeout
**Solution**: 
1. Check if SQL Server is healthy: `docker-compose ps`
2. Verify environment variables in `.env`
3. Check logs: `docker-compose logs sqlserver`

### Port Already in Use

**Issue**: Port 8080 or 1433 already in use
**Solution**: Stop the conflicting service or change ports in `docker-compose.yml`:

```yaml
ports:
  - "8081:8080"  # Change host port
```

### Database Not Initialized

**Issue**: Tables not created
**Solution**: 
1. Remove volumes and restart: `docker-compose down -v`
2. Start again: `docker-compose up --build`

### Application Fails to Build

**Issue**: Maven build errors
**Solution**:
1. Check Java version (should be Java 17)
2. Clear Maven cache in container
3. Review build logs: `docker-compose logs app`

## Development Workflow

### Making Code Changes

1. Make changes to your code
2. Rebuild and restart the app:
   ```powershell
   docker-compose up --build app
   ```

### Adding New Dependencies

1. Update `pom.xml`
2. Rebuild the image:
   ```powershell
   docker-compose build app
   docker-compose up app
   ```

### Database Schema Changes

1. Update SQL scripts in `init-db/`
2. Remove database volume and restart:
   ```powershell
   docker-compose down -v
   docker-compose up --build
   ```

## Production Considerations

For production deployment:

1. **Use secrets management** instead of `.env` file
2. **Enable SSL/TLS** for SQL Server connections
3. **Use persistent volume mounts** for database backup
4. **Configure resource limits** in docker-compose.yml:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 4G
   ```
5. **Set up health checks** and monitoring
6. **Use proper image tags** instead of `latest`
7. **Configure logging** with proper log drivers

## Cleaning Up

To completely remove all containers, networks, and volumes:

```powershell
docker-compose down -v --rmi all
```

## Support

For issues or questions:
1. Check application logs: `docker-compose logs app`
2. Check database logs: `docker-compose logs sqlserver`
3. Verify environment variables
4. Review this guide's troubleshooting section
