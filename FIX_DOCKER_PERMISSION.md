# Docker Permission Denied Fix

## ❌ Problem

You're seeing this error:
```
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

## ✅ Solution

Your user needs to be in the `docker` group. Here's how to fix it:

### Quick Fix (3 Steps)

```bash
# 1. Add your user to docker group
sudo usermod -aG docker $USER

# 2. Log out
logout

# 3. Log back in via SSH
ssh -i your-key.pem ubuntu@your-ec2-ip

# 4. Verify it works
docker ps
```

### Alternative: Use newgrp (No Logout Required)

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes without logout
newgrp docker

# Verify it works
docker ps

# Now run the deployment script again
./deploy-ec2.sh
```

---

## 🔍 Verify Docker Access

After logging back in, verify Docker works:

```bash
# Check groups
groups
# Should show: ubuntu ... docker

# Test Docker
docker ps
# Should NOT show permission denied

# Check Docker is running
sudo systemctl status docker
```

---

## 🚀 Resume Deployment

Once Docker access is fixed, run the deployment script again:

```bash
cd ~/PRM392_SaleApp
./deploy-ec2.sh
```

Or deploy manually:

```bash
# Load environment variables
source /etc/salesapp/env.sh

# Start services
docker-compose up -d sqlserver

# Wait for SQL Server
sleep 60

# Initialize database
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$DB_PASSWORD" -C \
  -i /docker-entrypoint-initdb.d/01-init-database.sql

# Start application
docker-compose up -d
```

---

## 🛠️ If Still Not Working

### Check Docker Service

```bash
# Check if Docker is running
sudo systemctl status docker

# If not running, start it
sudo systemctl start docker
sudo systemctl enable docker
```

### Verify Group Membership

```bash
# Check if user is in docker group
id -nG

# Verify docker group exists
getent group docker
```

### Force Reapply Groups

```bash
# Remove and re-add user to docker group
sudo gpasswd -d $USER docker
sudo usermod -aG docker $USER

# Log out and log back in
logout
```

---

## 💡 Why This Happens

- Docker daemon runs as root
- By default, only root can access Docker socket
- Adding user to `docker` group grants access
- Group changes require new login session to take effect

---

## ⚠️ Security Note

Being in the `docker` group gives root-equivalent access to the system. Only add trusted users to this group.

---

**After fixing, continue with deployment!** 🚀
