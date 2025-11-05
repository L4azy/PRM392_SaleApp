# SalesApp Docker Deployment Script for PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SalesApp Docker Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-Not (Test-Path ".env")) {
    Write-Host "[INFO] Creating .env file from .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host ""
    Write-Host "[WARNING] Please edit .env file with your actual credentials before continuing!" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to continue after editing .env file"
}

Write-Host "[INFO] Starting Docker containers..." -ForegroundColor Green
Write-Host ""

# Build and start containers
docker-compose up --build -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Application URL: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "  Swagger UI: http://localhost:8080/swagger-ui.html" -ForegroundColor Cyan
    Write-Host "  SQL Server: localhost:1433" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  To view logs: docker-compose logs -f" -ForegroundColor Yellow
    Write-Host "  To stop: docker-compose down" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed! Check the error messages above." -ForegroundColor Red
    Write-Host ""
}

Read-Host "Press Enter to exit"
