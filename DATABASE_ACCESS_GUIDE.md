# Accessing SQL Server Database on AWS EC2

This guide shows you how to access and manage the SQL Server database running in Docker on your EC2 instance.

## 🔌 Connection Methods

### Method 1: From Within EC2 Instance (CLI)

#### Using Docker Exec (Simplest)

```bash
# SSH to your EC2 instance first
ssh -i your-key.pem ubuntu@your-ec2-ip

# Access SQL Server CLI
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "$DB_PASSWORD" \
  -C

# You'll see SQL prompt
1>
```

Now you can run SQL commands:
```sql
-- List all databases
SELECT name FROM sys.databases;
GO

-- Switch to SalesAppDB
USE SalesAppDB;
GO

-- List all tables
SELECT name FROM sys.tables;
GO

-- Query data
SELECT * FROM Users;
GO

-- Exit
EXIT
```

#### Quick Queries (One-liners)

```bash
# List databases
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "SELECT name FROM sys.databases"

# Count users
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "SELECT COUNT(*) as UserCount FROM Users"

# View table structure
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "EXEC sp_help 'Users'"

# View all products
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "SELECT * FROM Products"
```

---

## 💻 Method 2: Remote Access (From Your Computer)

To connect from your local machine, you need to expose SQL Server port securely.

### Option A: SSH Tunnel (Recommended - Most Secure)

Create an SSH tunnel to access SQL Server securely:

```bash
# From your local machine (Windows PowerShell or Mac/Linux Terminal)
ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip
```

This forwards your local port 1433 to EC2's port 1433. **Keep this terminal open**.

Now you can connect using any SQL client to:
- **Host**: `localhost` (or `127.0.0.1`)
- **Port**: `1433`
- **Username**: `sa`
- **Password**: Your DB password
- **Database**: `SalesAppDB`

### Option B: Open Port 1433 (Less Secure - Use with Caution)

⚠️ **Security Warning**: Only do this if you understand the security implications!

1. **Update EC2 Security Group**:
   - Go to EC2 Console → Security Groups
   - Select your instance's security group
   - Add Inbound Rule:
     - Type: Custom TCP
     - Port: 1433
     - Source: **Your IP only** (not 0.0.0.0/0)
     - Description: SQL Server access

2. **Update Docker Compose** (if needed):
   The `docker-compose.yml` already exposes port 1433:
   ```yaml
   ports:
     - "1433:1433"
   ```

3. **Connect from your machine**:
   - **Host**: Your EC2 public IP
   - **Port**: 1433
   - **Username**: sa
   - **Password**: Your DB password

---

## 🖥️ Method 3: Using GUI Tools

### SQL Server Management Studio (SSMS) - Windows

1. **Download**: [SQL Server Management Studio](https://aka.ms/ssmsfullsetup)

2. **Connect via SSH Tunnel**:
   ```bash
   # Open SSH tunnel first (keep this running)
   ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip
   ```

3. **Open SSMS** and connect:
   - Server name: `localhost,1433`
   - Authentication: SQL Server Authentication
   - Login: `sa`
   - Password: Your DB password
   - Click **Connect**

4. **Browse database**: 
   - Expand **Databases** → **SalesAppDB** → **Tables**

### Azure Data Studio (Cross-platform)

1. **Download**: [Azure Data Studio](https://aka.ms/azuredatastudio)

2. **Open SSH tunnel**:
   ```bash
   ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip
   ```

3. **Create connection**:
   - Connection type: Microsoft SQL Server
   - Server: `localhost,1433`
   - Authentication type: SQL Login
   - User name: `sa`
   - Password: Your DB password
   - Database: `SalesAppDB`
   - Click **Connect**

### DBeaver (Cross-platform, Free)

1. **Download**: [DBeaver Community](https://dbeaver.io/download/)

2. **Open SSH tunnel**:
   ```bash
   ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip
   ```

3. **Create connection**:
   - Database: SQL Server
   - Host: localhost
   - Port: 1433
   - Database: SalesAppDB
   - Authentication: SQL Server Authentication
   - Username: sa
   - Password: Your DB password
   - Test Connection → OK → Finish

---

## 📊 Common Database Operations

### View All Tables and Row Counts

```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "SELECT t.name AS TableName, SUM(p.rows) AS RowCount FROM sys.tables t INNER JOIN sys.partitions p ON t.object_id = p.object_id WHERE p.index_id IN (0,1) GROUP BY t.name ORDER BY t.name"
```

### Check Database Size

```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "EXEC sp_spaceused"
```

### View Active Connections

```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "SELECT session_id, login_name, program_name, host_name, status FROM sys.dm_exec_sessions WHERE is_user_process = 1"
```

### Insert Sample Data

```bash
# Insert a test user
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "INSERT INTO Users (Username, PasswordHash, Email, Role) VALUES ('testuser', 'hash123', 'test@example.com', 'USER')"

# Verify insertion
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "SELECT * FROM Users WHERE Username = 'testuser'"
```

---

## 🔍 Running SQL Scripts

### From EC2 Instance

```bash
# Create a SQL script
nano ~/query.sql
```

Add your SQL:
```sql
USE SalesAppDB;
GO

-- Your queries here
SELECT COUNT(*) as TotalOrders FROM Orders;
GO

SELECT TOP 10 * FROM Products ORDER BY Price DESC;
GO
```

Execute it:
```bash
docker exec -i salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C < ~/query.sql
```

### From Your Local Machine (via SSH)

```bash
# Create script locally
nano query.sql

# Execute remotely
cat query.sql | ssh -i your-key.pem ubuntu@your-ec2-ip \
  "docker exec -i salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '$DB_PASSWORD' -C"
```

---

## 💾 Database Backup and Restore

### Create Backup

```bash
# Full backup
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/SalesAppDB_$(date +%Y%m%d).bak' WITH FORMAT, INIT, NAME = 'Full Backup'"

# Copy backup to EC2 instance
docker cp salesapp-sqlserver:/var/opt/mssql/backup/SalesAppDB_20251105.bak ~/backup.bak

# Download to your local machine
scp -i your-key.pem ubuntu@your-ec2-ip:~/backup.bak ./local-backup.bak
```

### Restore Backup

```bash
# Upload backup to EC2
scp -i your-key.pem ./local-backup.bak ubuntu@your-ec2-ip:~/restore.bak

# Copy into container
docker cp ~/restore.bak salesapp-sqlserver:/var/opt/mssql/backup/restore.bak

# Restore database
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "RESTORE DATABASE SalesAppDB FROM DISK = '/var/opt/mssql/backup/restore.bak' WITH REPLACE"
```

---

## 🔐 Create Additional Database Users (Security Best Practice)

Instead of using `sa` for everything, create application-specific users:

```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB \
  -Q "CREATE LOGIN appuser WITH PASSWORD = 'AppUser@Pass123'; CREATE USER appuser FOR LOGIN appuser; ALTER ROLE db_owner ADD MEMBER appuser;"
```

Update your `docker-compose.yml` to use this user:
```yaml
environment:
  - DB_USERNAME=appuser
  - DB_PASSWORD=AppUser@Pass123
```

---

## 🔧 Troubleshooting Database Access

### Can't Connect from CLI

```bash
# Check if container is running
docker-compose ps

# Check SQL Server logs
docker-compose logs sqlserver

# Test connection
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT @@VERSION"
```

### SSH Tunnel Issues

```bash
# Check if tunnel is active (from local machine)
netstat -an | grep 1433

# If not, restart tunnel
ssh -i your-key.pem -L 1433:localhost:1433 ubuntu@your-ec2-ip
```

### Password Issues

```bash
# Check environment variable
echo $DB_PASSWORD

# Or reload from env file
source /etc/salesapp/env.sh
echo $DB_PASSWORD
```

### Permission Denied

```bash
# Ensure you're using the correct user
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "SELECT name FROM sys.database_principals WHERE type = 'S'"
```

---

## 📱 Quick Reference Commands

```bash
# === Connection ===
# CLI access
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C

# === Queries ===
# List databases
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases"

# List tables
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB -Q "SELECT name FROM sys.tables"

# Count rows in table
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB -Q "SELECT COUNT(*) FROM Users"

# === Backup ===
# Create backup
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "BACKUP DATABASE SalesAppDB TO DISK = '/var/opt/mssql/backup/backup.bak'"

# Copy backup out
docker cp salesapp-sqlserver:/var/opt/mssql/backup/backup.bak ./backup.bak

# === Monitoring ===
# Check database size
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d SalesAppDB -Q "EXEC sp_spaceused"

# View connections
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT * FROM sys.dm_exec_sessions WHERE is_user_process = 1"
```

---

## 💡 Best Practices

1. **Use SSH Tunnels** for remote access (most secure)
2. **Don't expose port 1433** to the internet (0.0.0.0/0)
3. **Create application-specific users** instead of using `sa`
4. **Regular backups** to S3 or external storage
5. **Monitor database size** and performance
6. **Use read-only users** for reporting/analytics
7. **Enable SSL/TLS** for production connections

---

## 🎓 Learning SQL Server

If you're new to SQL Server, here are some useful commands:

```sql
-- Show current database
SELECT DB_NAME();
GO

-- Show SQL Server version
SELECT @@VERSION;
GO

-- Show current user
SELECT CURRENT_USER;
GO

-- List all users
SELECT name FROM sys.database_principals WHERE type = 'S';
GO

-- Table info
EXEC sp_help 'Users';
GO

-- Column info
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Users';
GO
```

---

## 📚 Additional Resources

- [SQL Server T-SQL Reference](https://learn.microsoft.com/en-us/sql/t-sql/)
- [Azure Data Studio Documentation](https://learn.microsoft.com/en-us/sql/azure-data-studio/)
- [SQL Server Management Studio](https://learn.microsoft.com/en-us/sql/ssms/)
- [Docker SQL Server Guide](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)

---

**Created**: November 5, 2025  
**Purpose**: Database access guide for AWS EC2 deployment
