# AWS Systems Manager Parameter Store Setup

This guide shows how to use AWS Parameter Store for secure credential management (no .env files needed).

## 🔐 Why Use Parameter Store?

✅ **Secure**: Credentials encrypted at rest  
✅ **Centralized**: Manage all secrets in one place  
✅ **Audit**: Track who accessed what and when  
✅ **No .env files**: Nothing stored on disk  
✅ **IAM Integration**: Fine-grained access control  

---

## 📝 Step 1: Store Parameters

### Option A: Using AWS Console

1. Go to **AWS Console** → **Systems Manager** → **Parameter Store**
2. Click **Create parameter** for each value:

| Name | Type | Value |
|------|------|-------|
| `/salesapp/db-password` | SecureString | `YourStrong@Passw0rd123` |
| `/salesapp/signer-key` | SecureString | `your-32-char-jwt-key` |
| `/salesapp/gemini-api-key` | SecureString | `your-gemini-key` |
| `/salesapp/cloudinary-cloud-name` | String | `your-cloud-name` |
| `/salesapp/cloudinary-api-key` | String | `your-api-key` |
| `/salesapp/cloudinary-api-secret` | SecureString | `your-api-secret` |

### Option B: Using AWS CLI

```bash
# Configure AWS CLI first
aws configure

# Store parameters
aws ssm put-parameter \
    --name "/salesapp/db-password" \
    --value "YourStrong@Passw0rd123" \
    --type "SecureString" \
    --description "Database password for SalesApp"

aws ssm put-parameter \
    --name "/salesapp/signer-key" \
    --value "your-32-character-minimum-jwt-signing-key-here" \
    --type "SecureString" \
    --description "JWT signing key for SalesApp"

aws ssm put-parameter \
    --name "/salesapp/gemini-api-key" \
    --value "your-gemini-api-key" \
    --type "SecureString" \
    --description "Gemini AI API key"

aws ssm put-parameter \
    --name "/salesapp/cloudinary-cloud-name" \
    --value "your-cloudinary-cloud-name" \
    --type "String" \
    --description "Cloudinary cloud name"

aws ssm put-parameter \
    --name "/salesapp/cloudinary-api-key" \
    --value "your-cloudinary-api-key" \
    --type "String" \
    --description "Cloudinary API key"

aws ssm put-parameter \
    --name "/salesapp/cloudinary-api-secret" \
    --value "your-cloudinary-api-secret" \
    --type "SecureString" \
    --description "Cloudinary API secret"
```

---

## 🔑 Step 2: Create IAM Role

### Create Role
1. Go to **IAM Console** → **Roles** → **Create Role**
2. Select **AWS Service** → **EC2**
3. Click **Next**

### Attach Policy
Create a custom policy or use managed policy:

**Option A: Use Managed Policy**
- Attach: `AmazonSSMReadOnlyAccess`

**Option B: Custom Policy (More Secure)**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/salesapp/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*"
        }
    ]
}
```

### Name the Role
- Role name: `SalesApp-EC2-Role`
- Click **Create Role**

---

## 🖥️ Step 3: Attach Role to EC2

1. Go to **EC2 Console** → **Instances**
2. Select your EC2 instance
3. **Actions** → **Security** → **Modify IAM Role**
4. Select `SalesApp-EC2-Role`
5. Click **Update IAM Role**

---

## 📥 Step 4: Fetch Parameters on EC2

### Create Startup Script

```bash
# Create directory
sudo mkdir -p /etc/salesapp

# Create script to fetch parameters
sudo nano /etc/salesapp/fetch-params.sh
```

Add this content:
```bash
#!/bin/bash

# Fetch parameters from AWS Parameter Store
export DB_PASSWORD=$(aws ssm get-parameter --name "/salesapp/db-password" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export SIGNER_KEY=$(aws ssm get-parameter --name "/salesapp/signer-key" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export GEMINI_API_KEY=$(aws ssm get-parameter --name "/salesapp/gemini-api-key" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export CLOUD_NAME=$(aws ssm get-parameter --name "/salesapp/cloudinary-cloud-name" --query "Parameter.Value" --output text --region us-east-1)
export API_KEY=$(aws ssm get-parameter --name "/salesapp/cloudinary-api-key" --query "Parameter.Value" --output text --region us-east-1)
export API_SECRET=$(aws ssm get-parameter --name "/salesapp/cloudinary-api-secret" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

echo "Parameters fetched successfully!"
```

Make it executable:
```bash
sudo chmod +x /etc/salesapp/fetch-params.sh
sudo chown ubuntu:ubuntu /etc/salesapp/fetch-params.sh
```

### Use in Deployment

```bash
# Source the parameters
source /etc/salesapp/fetch-params.sh

# Now deploy with docker-compose
cd ~/PRM392_SaleApp
docker-compose up -d
```

---

## 🤖 Step 5: Automated Systemd Service

Create a service that fetches parameters on startup:

```bash
sudo nano /etc/systemd/system/salesapp.service
```

Add:
```ini
[Unit]
Description=SalesApp Docker Compose
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/PRM392_SaleApp
ExecStartPre=/bin/bash -c 'source /etc/salesapp/fetch-params.sh && env > /etc/salesapp/runtime.env'
EnvironmentFile=/etc/salesapp/runtime.env
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable salesapp
sudo systemctl start salesapp
sudo systemctl status salesapp
```

---

## ✅ Step 6: Verify

### Test Parameter Retrieval
```bash
source /etc/salesapp/fetch-params.sh
echo $DB_PASSWORD
echo $SIGNER_KEY
```

### Test Application
```bash
docker-compose ps
curl http://localhost:8080/swagger-ui/index.html
```

---

## 🔄 Update Parameters

### Using AWS Console
1. Go to Parameter Store
2. Select parameter
3. Edit → Update value → Save

### Using AWS CLI
```bash
aws ssm put-parameter \
    --name "/salesapp/db-password" \
    --value "NewPassword123!" \
    --type "SecureString" \
    --overwrite
```

### Reload on EC2
```bash
source /etc/salesapp/fetch-params.sh
docker-compose restart
```

---

## 🛡️ Security Best Practices

1. **Use SecureString** for all sensitive values
2. **Limit IAM permissions** to specific parameters only
3. **Enable CloudTrail** to audit parameter access
4. **Use different parameters** for dev/staging/prod
5. **Rotate secrets regularly**
6. **Never log parameter values**

---

## 📊 Monitoring

### Enable CloudWatch Logs
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
```

### Create CloudWatch Alarms
1. Go to **CloudWatch** → **Alarms**
2. Create alarm for:
   - High CPU usage
   - High memory usage
   - Application errors

---

## 💡 Tips

- **Parameter naming**: Use consistent naming like `/app-name/environment/parameter`
- **Tagging**: Tag parameters for better organization
- **Version history**: Parameter Store keeps version history
- **Cost**: First 10,000 parameters are free

---

## 🆘 Troubleshooting

### "AccessDeniedException"
- Check IAM role is attached to EC2
- Verify IAM policy has correct permissions
- Check parameter names match exactly

### Parameters not found
```bash
# List all parameters
aws ssm describe-parameters --query 'Parameters[*].Name'

# Get specific parameter
aws ssm get-parameter --name "/salesapp/db-password" --with-decryption
```

### Can't fetch parameters
```bash
# Check AWS CLI is configured
aws sts get-caller-identity

# Check IAM role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

---

## 📚 Additional Resources

- [AWS Parameter Store Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS CLI Parameter Store Reference](https://docs.aws.amazon.com/cli/latest/reference/ssm/index.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**Created**: November 5, 2025  
**Best for**: Production environments requiring maximum security
