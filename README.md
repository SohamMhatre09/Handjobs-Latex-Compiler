# LaTeX Compiler VM - Production Ready

This directory contains all the files needed to run a secure, production-ready LaTeX compiler service with API key authentication and Gunicorn multithreading.

## 🔐 Security Features

- **API Key Authentication**: All endpoints protected with `X-API-KEY` header
- **Security Headers**: HSTS, XSS Protection, Content Security Policy
- **Non-root Container**: Runs with dedicated user for security
- **Resource Limits**: Memory and CPU constraints
- **Rate Limiting**: Built into Gunicorn configuration

## 🚀 Quick Production Setup

1. **Copy this entire `latexvm` folder to your production VM**
2. **Set your API key (optional - default is provided):**
   ```bash
   export API_KEY="your-secure-api-key-here"
   ```
3. **Run the setup script:**
   ```bash
   chmod +x setup_latex_vm.sh
   ./setup_latex_vm.sh
   ```

## 📋 What's Included

- `app.py` - Secured Flask service with API key authentication
- `gunicorn.conf.py` - Production Gunicorn configuration with multithreading
- `start_production.sh` - Production startup script
- `Dockerfile` - Hardened Docker image with security best practices
- `docker-compose.yml` - Production orchestration with resource limits
- `latex-compiler.service` - Systemd service for native deployment
- `test_api.sh` - API authentication testing script
- `requirements.txt` - Python dependencies
- `setup_latex_vm.sh` - Automated setup script

## 🔧 Production Deployment Options

### Option 1: Docker Compose (Recommended)

```bash
# Build and start production service
docker-compose build
docker-compose up -d

# Check service status
docker-compose ps
docker-compose logs -f latex-compiler-prod
```

### Option 2: Native Systemd Service

```bash
# Copy service to production location
sudo mkdir -p /opt/latex-compiler
sudo cp -r * /opt/latex-compiler/
sudo chown -R www-data:www-data /opt/latex-compiler

# Install and start systemd service
sudo cp latex-compiler.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable latex-compiler
sudo systemctl start latex-compiler

# Check service status
sudo systemctl status latex-compiler
```

### Option 3: Direct Gunicorn

```bash
# Install dependencies
pip3 install -r requirements.txt

# Set environment variables
export API_KEY="djsakjc213hjbkk3h123jkb123kbj"
export FLASK_ENV=production

# Start with Gunicorn
./start_production.sh
```

## 🌐 API Endpoints

All endpoints require the `X-API-KEY` header with value: `djsakjc213hjbkk3h123jkb123kbj`

- **Health Check:** `GET /health`
  ```bash
  curl -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" http://localhost:8080/health
  ```

- **Compile LaTeX:** `POST /compile`
  ```bash
  curl -X POST -H "Content-Type: application/json" \
       -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" \
       -d '{"latex_content": "\\documentclass{article}\\begin{document}Hello World\\end{document}", "timeout": 30}' \
       http://localhost:8080/compile
  ```

- **Test Compilation:** `POST /test`
  ```bash
  curl -X POST -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" \
       http://localhost:8080/test
  ```

## 🧪 Testing API Authentication

Run the included test script to verify API key authentication:

```bash
./test_api.sh
```

This will test:
- Health check without API key (should fail with 401)
- Health check with correct API key (should succeed)
- Health check with wrong API key (should fail with 403)
- Compile endpoint authentication

## ⚙️ Production Configuration

### Gunicorn Workers
- **Workers**: `CPU cores * 2 + 1` (auto-calculated)
- **Worker Class**: Synchronous (suitable for CPU-intensive LaTeX compilation)
- **Timeout**: 60 seconds
- **Max Requests**: 1000 per worker (prevents memory leaks)

### Security Headers
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`
- `Content-Security-Policy: default-src 'self'`

### Resource Limits (Docker)
- **Memory**: 2GB limit, 512MB reserved
- **CPU**: 2.0 cores limit, 0.5 cores reserved

## 📊 Monitoring & Logging

### Docker Compose Monitoring
```bash
# Check service status
docker-compose ps

# View real-time logs
docker-compose logs -f latex-compiler-prod

# View Gunicorn access logs
docker exec latex-compiler-prod tail -f /var/log/gunicorn/access.log

# View error logs
docker exec latex-compiler-prod tail -f /var/log/gunicorn/error.log

# Check resource usage
docker stats latex-compiler-prod

# Restart service
docker-compose restart latex-compiler-prod
```

### Systemd Monitoring
```bash
# Service status
sudo systemctl status latex-compiler

# View logs
sudo journalctl -u latex-compiler -f

# Restart service
sudo systemctl restart latex-compiler

# Check worker processes
ps aux | grep gunicorn
```

### Health Monitoring Script
```bash
# Create a simple monitoring script
cat > monitor_latex_service.sh << 'EOF'
#!/bin/bash
API_KEY="djsakjc213hjbkk3h123jkb123kbj"
while true; do
    if curl -s -H "X-API-KEY: $API_KEY" http://localhost:8080/health > /dev/null; then
        echo "$(date): Service is healthy"
    else
        echo "$(date): Service is DOWN!"
        # Add notification logic here (email, Slack, etc.)
    fi
    sleep 60
done
EOF

chmod +x monitor_latex_service.sh
./monitor_latex_service.sh &
```

## 🔗 Integration Examples

### Environment Variables
```bash
# In your main backend service
export LATEX_COMPILER_URL="http://YOUR_VM_IP:8080/compile"
export LATEX_API_KEY="djsakjc213hjbkk3h123jkb123kbj"
```

### Python Integration Example
```python
import requests

def compile_latex_to_pdf(latex_content):
    url = "http://YOUR_VM_IP:8080/compile"
    headers = {
        "Content-Type": "application/json",
        "X-API-KEY": "djsakjc213hjbkk3h123jkb123kbj"
    }
    data = {
        "latex_content": latex_content,
        "timeout": 30
    }
    
    response = requests.post(url, json=data, headers=headers)
    
    if response.status_code == 200:
        return response.content  # PDF bytes
    else:
        raise Exception(f"Compilation failed: {response.json()}")
```

### Node.js Integration Example
```javascript
const axios = require('axios');

async function compileLatexToPdf(latexContent) {
    const response = await axios.post('http://YOUR_VM_IP:8080/compile', {
        latex_content: latexContent,
        timeout: 30
    }, {
        headers: {
            'Content-Type': 'application/json',
            'X-API-KEY': 'djsakjc213hjbkk3h123jkb123kbj'
        },
        responseType: 'arraybuffer'
    });
    
    return response.data; // PDF buffer
}
```

## 💾 System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4GB (2GB for service + 2GB system)
- **Disk**: 5GB free space
- **OS**: Ubuntu 20.04+ or compatible Linux

### Recommended Production
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 10GB+ SSD
- **Network**: 1Gbps+

### Storage Details
- **Docker Image**: ~2GB (includes full LaTeX packages)
- **Runtime Memory**: ~500MB RAM per compilation
- **Logs**: Rotated automatically, ~100MB max
- **Temporary Files**: Auto-cleaned after compilation

## 🔒 Security Checklist

- ✅ API key authentication on all endpoints
- ✅ Non-root container user
- ✅ Security headers enabled
- ✅ Resource limits configured
- ✅ No persistent storage of user content
- ✅ Automatic cleanup of temporary files
- ✅ Network isolation (Docker)
- ✅ Capability restrictions

## 🚨 Troubleshooting

### Service Issues
```bash
# Service not responding
docker-compose logs latex-compiler-prod

# Check if port is open
netstat -tlnp | grep 8080

# Test API key authentication
curl -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" http://localhost:8080/health
```

### Compilation Failures
```bash
# Check detailed error logs
docker-compose logs latex-compiler-prod | grep ERROR

# Test with minimal document
curl -X POST -H "Content-Type: application/json" \
     -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" \
     http://localhost:8080/test
```

### Performance Issues
```bash
# Check resource usage
docker stats latex-compiler-prod

# Monitor worker processes
docker exec latex-compiler-prod ps aux | grep gunicorn

# Check memory usage
docker exec latex-compiler-prod free -h
```

### Common Error Solutions

**401 Unauthorized**: Missing or incorrect API key
```bash
# Ensure X-API-KEY header is included
curl -H "X-API-KEY: djsakjc213hjbkk3h123jkb123kbj" ...
```

**408 Timeout**: LaTeX compilation taking too long
```bash
# Increase timeout in request
{"latex_content": "...", "timeout": 60}
```

**500 Internal Error**: LaTeX syntax or package issues
```bash
# Check logs for specific LaTeX errors
docker-compose logs latex-compiler-prod | tail -50
```

## 🔄 Updates & Maintenance

```bash
# Update the service
git pull  # if using git
docker-compose build --no-cache
docker-compose up -d

# Cleanup old images
docker image prune -f

# Backup configuration
tar -czf latex-compiler-backup.tar.gz *.yml *.py *.sh *.conf
```

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review service logs for error details
3. Test with the included `test_api.sh` script
4. Verify API key configuration

**Service is now production-ready with:**
- ✅ API key authentication (`X-API-KEY: djsakjc213hjbkk3h123jkb123kbj`)
- ✅ Gunicorn multithreading for high performance
- ✅ Security hardening and resource limits
- ✅ Comprehensive monitoring and logging
- ✅ Production deployment options
# Handjobs-Latex-Compiler
