@echo off
echo ========================================
echo   SalesApp Docker Deployment Script
echo ========================================
echo.

REM Check if .env file exists
if not exist ".env" (
    echo [INFO] Creating .env file from .env.example...
    copy .env.example .env
    echo.
    echo [WARNING] Please edit .env file with your actual credentials before continuing!
    echo.
    pause
)

echo [INFO] Starting Docker containers...
echo.

REM Build and start containers
docker-compose up --build -d

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   Deployment Successful!
    echo ========================================
    echo.
    echo   Application URL: http://localhost:8080
    echo   Swagger UI: http://localhost:8080/swagger-ui.html
    echo   SQL Server: localhost:1433
    echo.
    echo   To view logs: docker-compose logs -f
    echo   To stop: docker-compose down
    echo.
) else (
    echo.
    echo [ERROR] Deployment failed! Check the error messages above.
    echo.
)

pause
