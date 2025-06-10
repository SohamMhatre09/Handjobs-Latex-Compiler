# LaTeX Compiler API - Production Deployment

## 🚀 Quick Deploy

**One-command deployment:**

```bash
sudo ./deploy-production.sh
```

## 📋 Requirements

- Ubuntu/Debian server with Docker and Docker Compose installed
- Domain pointing to your server (supports Cloudflare proxy)
- sudo privileges
- Ports 80 and 443 open

## 🔧 What the script does

1. **Cleans everything** - Removes old containers, images, and SSL certificates
2. **Fixes app.py** - Adds public root endpoint for health checks
3. **Fixes nginx.conf** - Cloudflare-compatible configuration
4. **Obtains SSL certificates** - Fresh Let's Encrypt certificates
5. **Deploys services** - Builds and starts Docker containers
6. **Sets up auto-renewal** - SSL certificates auto-renew
7. **Tests everything** - Verifies HTTP/HTTPS functionality

## 🌐 API Endpoints

After deployment:

### Public Endpoints
- `GET /` - Service information (no authentication required)

### Authenticated Endpoints (require `X-API-KEY` header)
- `GET /health` - Health check
- `POST /compile` - Compile LaTeX to PDF

## 🔑 API Usage Examples

```bash
# Test service (no auth needed)
curl https://latex-compiler.handjobs.co.in/

# Health check (with API key)
curl -H "X-API-KEY: your-api-key" \
     https://latex-compiler.handjobs.co.in/health

# Compile LaTeX (with API key)
curl -X POST \
     -H "X-API-KEY: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"latex_content": "\\documentclass{article}\\begin{document}Hello World\\end{document}"}' \
     https://latex-compiler.handjobs.co.in/compile \
     --output document.pdf
```

## ☁️ Cloudflare Setup

If using Cloudflare proxy (orange cloud):

1. In Cloudflare dashboard: **SSL/TLS** → **Overview**
2. Set encryption mode to **"Full (strict)"**
3. Or disable proxy (grey cloud) and point A record directly to server

## 🔄 Maintenance Commands

```bash
# Check service status
sudo docker compose ps

# View logs
sudo docker compose logs

# Restart services
sudo docker compose restart

# Update and redeploy
git pull
sudo ./deploy-production.sh
```

## 📁 Project Structure

```
Handjobs-Latex-Compiler/
├── app.py                 # Flask application (fixed with root route)
├── nginx.conf             # Nginx config (Cloudflare compatible)
├── docker-compose.yml     # Docker services definition
├── Dockerfile             # App container definition
├── requirements.txt       # Python dependencies
├── deploy-production.sh   # Main deployment script
├── .env                   # Environment variables (API_KEY)
└── DEPLOY.md             # This file
```

## 🎯 Success Indicators

After running the deployment script, you should see:

- ✅ HTTP response: 301 (redirect to HTTPS)
- ✅ HTTPS response: 200 (service running)
- ✅ Root endpoint returns service information
- ✅ SSL certificate auto-renewal configured

## 🔍 Troubleshooting

**HTTPS 521 Error:**
- Check Cloudflare SSL settings
- Verify domain points to correct server IP
- Check firewall (ports 80, 443 open)

**404 Errors:**
- Service should now have root route (`/`)
- Check container logs: `sudo docker compose logs`

**SSL Issues:**
- Verify certificate: `openssl s_client -connect latex-compiler.handjobs.co.in:443`
- Check Let's Encrypt logs: `/var/log/letsencrypt/letsencrypt.log`

---

**🎉 Ready to deploy? Run: `sudo ./deploy-production.sh`**
