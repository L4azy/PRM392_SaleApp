# PRM392_SaleApp

An application developed with Java Spring Boot & Mobile App

## 🚀 Quick Start with Docker

### Prerequisites
- Docker Desktop installed
- At least 4GB of free RAM

### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PRM392_SaleApp
   ```

2. **Configure environment variables**
   ```bash
   # Copy the example file
   copy .env.example .env
   
   # Edit .env with your credentials
   notepad .env
   ```

3. **Start the application**
   
   **Option A: Using the startup script (Recommended)**
   ```bash
   # Windows Command Prompt
   start-docker.bat
   
   # Or PowerShell
   .\start-docker.ps1
   ```
   
   **Option B: Using Docker Compose directly**
   ```bash
   docker-compose up --build -d
   ```

4. **Access the application**
   - **API**: http://localhost:8080
   - **Swagger UI**: http://localhost:8080/swagger-ui.html
   - **SQL Server**: localhost:1433 (sa/your-password)

### Managing the Application

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Rebuild after code changes
docker-compose up --build
```

## ☁️ AWS EC2 Deployment

Deploy to AWS EC2 in 3 simple steps:

```bash
# 1. SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# 2. Run deployment script
curl -o deploy-ec2.sh https://raw.githubusercontent.com/L4azy/PRM392_SaleApp/main/deploy-ec2.sh
chmod +x deploy-ec2.sh
./deploy-ec2.sh

# 3. Access your app
http://your-ec2-ip:8080

# 4. Access database (from EC2)
docker exec -it salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C
```

**See**: [EC2 Quick Start](EC2_QUICK_START.md) | [Database Access](DATABASE_ACCESS_GUIDE.md) | [Full EC2 Guide](AWS_EC2_DEPLOYMENT.md) | [Parameter Store](AWS_PARAMETER_STORE_GUIDE.md)

## 📚 Documentation

### Local Development
- [Docker Deployment Guide](DOCKER_DEPLOYMENT.md) - Complete local deployment
- [Docker Quick Reference](DOCKER_QUICK_REFERENCE.md) - Essential commands
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues

### AWS Deployment  
- [EC2 Quick Start](EC2_QUICK_START.md) - ⭐ Start here for AWS
- [AWS EC2 Deployment](AWS_EC2_DEPLOYMENT.md) - Complete EC2 guide
- [AWS Parameter Store](AWS_PARAMETER_STORE_GUIDE.md) - Secure secrets management

### Application Features
- [VNPAY API Guide](SalesApp/VNPAY_API_GUIDE.md) - Payment integration
- [AI Training Guide](SalesApp/TRAIN_AI_COMPLETE_GUIDE.md) - AI features setup

## 🏗️ Architecture

- **Backend**: Spring Boot 3.2.1 with Java 17
- **Database**: Microsoft SQL Server 2022
- **Containerization**: Docker & Docker Compose
- **API Documentation**: OpenAPI/Swagger

## 📦 Tech Stack

- Spring Boot (Web, Security, Data JPA, WebSocket)
- SQL Server
- JWT Authentication
- Cloudinary (Image storage)
- Google Gemini AI
- MapStruct
- Lombok

## 🔧 Development

See [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) for detailed development workflow, troubleshooting, and production considerations.
