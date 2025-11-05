#!/bin/bash

#############################################
# SalesApp AWS EC2 Deployment Script
# 
# This script automates the deployment of
# SalesApp on AWS EC2 without .env files
#############################################

set -e  # Exit on error

echo "=========================================="
echo "  SalesApp AWS EC2 Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

echo "Step 1: Checking prerequisites..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_info "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed"
    print_info "Please log out and log back in, then run this script again"
    exit 0
else
    print_success "Docker is installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_info "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose is installed"
fi

echo ""
echo "Step 2: Setting up environment variables..."
echo ""

# Check if environment file exists
ENV_FILE="/etc/salesapp/env.sh"
if [ ! -f "$ENV_FILE" ]; then
    print_info "Environment file not found. Creating..."
    
    # Prompt for environment variables
    read -p "Enter DB Password (strong password with 8+ chars, mixed case, numbers, symbols): " DB_PASSWORD
    read -p "Enter JWT Signer Key (32+ characters): " SIGNER_KEY
    read -p "Enter Gemini API Key (or press Enter to skip): " GEMINI_API_KEY
    read -p "Enter Cloudinary Cloud Name (or press Enter to skip): " CLOUD_NAME
    read -p "Enter Cloudinary API Key (or press Enter to skip): " API_KEY
    read -p "Enter Cloudinary API Secret (or press Enter to skip): " API_SECRET
    
    # Create directory
    sudo mkdir -p /etc/salesapp
    
    # Create environment file
    sudo tee "$ENV_FILE" > /dev/null <<EOF
#!/bin/bash
export DB_PASSWORD="$DB_PASSWORD"
export SIGNER_KEY="$SIGNER_KEY"
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
export GEMINI_API_KEY="${GEMINI_API_KEY:-your-gemini-api-key}"
export CLOUD_NAME="${CLOUD_NAME:-your-cloudinary-cloud-name}"
export API_KEY="${API_KEY:-your-cloudinary-api-key}"
export API_SECRET="${API_SECRET:-your-cloudinary-api-secret}"
EOF
    
    # Secure the file
    sudo chmod 600 "$ENV_FILE"
    sudo chown $USER:$USER "$ENV_FILE"
    
    print_success "Environment file created at $ENV_FILE"
else
    print_success "Environment file found"
fi

# Load environment variables
source "$ENV_FILE"
print_success "Environment variables loaded"

echo ""
echo "Step 3: Checking project directory..."
echo ""

PROJECT_DIR="$HOME/PRM392_SaleApp"

if [ ! -d "$PROJECT_DIR" ]; then
    print_info "Project directory not found. Cloning repository..."
    read -p "Enter GitHub repository URL (or press Enter for default): " REPO_URL
    REPO_URL=${REPO_URL:-https://github.com/L4azy/PRM392_SaleApp.git}
    
    git clone "$REPO_URL" "$PROJECT_DIR"
    print_success "Repository cloned"
else
    print_success "Project directory found"
    print_info "Pulling latest changes..."
    cd "$PROJECT_DIR"
    git pull origin main || print_info "Could not pull latest changes (continuing anyway)"
fi

cd "$PROJECT_DIR"

echo ""
echo "Step 4: Stopping existing containers..."
echo ""

if docker-compose ps | grep -q "Up"; then
    docker-compose down
    print_success "Stopped existing containers"
else
    print_info "No running containers found"
fi

echo ""
echo "Step 5: Starting SQL Server..."
echo ""

# Start SQL Server first
docker-compose up -d sqlserver

print_info "Waiting for SQL Server to start (60 seconds)..."
sleep 60

# Check if database exists
DB_EXISTS=$(docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT name FROM sys.databases WHERE name = 'SalesAppDB'" -h -1 | grep -c "SalesAppDB" || echo "0")

if [ "$DB_EXISTS" -eq "0" ]; then
    print_info "Database not found. Initializing..."
    docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -i /docker-entrypoint-initdb.d/01-init-database.sql
    print_success "Database initialized"
else
    print_success "Database already exists"
fi

echo ""
echo "Step 6: Building and starting application..."
echo ""

docker-compose up --build -d

print_info "Waiting for application to start (30 seconds)..."
sleep 30

echo ""
echo "Step 7: Verifying deployment..."
echo ""

# Check container status
if docker-compose ps | grep -q "salesapp-backend.*Up"; then
    print_success "Application container is running"
else
    print_error "Application container is not running"
    docker-compose logs app --tail=50
    exit 1
fi

if docker-compose ps | grep -q "salesapp-sqlserver.*Up"; then
    print_success "SQL Server container is running"
else
    print_error "SQL Server container is not running"
    docker-compose logs sqlserver --tail=50
    exit 1
fi

# Test API endpoint
print_info "Testing API endpoint..."
sleep 10
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/swagger-ui/index.html | grep -q "200"; then
    print_success "API is responding"
else
    print_error "API is not responding"
    print_info "Check logs with: docker-compose logs -f"
fi

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Access URLs:"
echo "  - API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR-EC2-IP'):8080"
echo "  - Swagger: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR-EC2-IP'):8080/swagger-ui/index.html"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Restart: docker-compose restart"
echo "  - Stop: docker-compose down"
echo "  - Update: ~/deploy-salesapp.sh"
echo ""
echo "Environment file: $ENV_FILE"
echo ""
echo "=========================================="

# Create update script
print_info "Creating update script..."
cat > "$HOME/deploy-salesapp.sh" <<'EOFSCRIPT'
#!/bin/bash
echo "Updating SalesApp..."
source /etc/salesapp/env.sh
cd ~/PRM392_SaleApp
git pull origin main
docker-compose down
docker-compose up --build -d
echo "Update complete!"
EOFSCRIPT

chmod +x "$HOME/deploy-salesapp.sh"
print_success "Update script created at ~/deploy-salesapp.sh"

echo ""
print_success "All done! 🚀"
