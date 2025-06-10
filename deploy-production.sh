#!/bin/bash

# ========================================
# PRODUCTION DEPLOYMENT SCRIPT
# ========================================
# Complete deployment script for LaTeX Compiler with HTTPS
# 
# REQUIREMENTS:
# - Ubuntu/Debian server with Docker and Docker Compose
# - Domain pointing to server (Cloudflare compatible)
# - sudo privileges
#
# COMMANDS TO RUN:
# chmod +x deploy-production.sh
# sudo ./deploy-production.sh
#
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PRODUCTION DEPLOYMENT SCRIPT${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run with sudo!${NC}"
    echo -e "${YELLOW}Run: sudo ./deploy-production.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  This will:"
echo "- Clean all Docker containers and images"
echo "- Remove existing SSL certificates"
echo "- Fix app.py (add root route)"
echo "- Fix nginx.conf (Cloudflare compatible)"
echo "- Obtain fresh SSL certificates"
echo "- Deploy with HTTPS${NC}"
echo ""
echo -e "${YELLOW}⏳ Starting in 5 seconds... (Press Ctrl+C to cancel)${NC}"
sleep 5

# ========================================
# 1. CLEAN EVERYTHING
# ========================================
echo -e "${BLUE}🧹 Step 1: Cleaning everything...${NC}"

# Stop and remove all containers
echo "Stopping all Docker containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker rmi $(docker images -q) 2>/dev/null || true
docker system prune -af --volumes

# Remove SSL certificates
echo "Removing old SSL certificates..."
rm -rf /etc/letsencrypt/
rm -rf /var/lib/letsencrypt/
rm -rf /var/log/letsencrypt/

# Stop conflicting services
echo "Stopping conflicting services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
pkill -f nginx || true

echo -e "${GREEN}✅ Cleanup complete${NC}"

# ========================================
# 2. SYSTEM UPDATES
# ========================================
echo -e "${BLUE}📦 Step 2: Updating system...${NC}"
apt update
apt autoremove -y
apt autoclean
apt install -y certbot curl
echo -e "${GREEN}✅ System updated${NC}"

# ========================================
# 3. FIX APPLICATION CODE
# ========================================
echo -e "${BLUE}🔧 Step 3: Fixing app.py...${NC}"

# Backup original app.py
cp app.py app.py.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create fixed app.py with root route
cat > app.py << 'EOF'
from flask import Flask, request, jsonify
import subprocess
import tempfile
import os
from functools import wraps
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)

API_KEY = os.environ.get('API_KEY')

def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-KEY')
        if not api_key or api_key != API_KEY:
            return jsonify({'error': 'Invalid API key'}), 401
        return f(*args, **kwargs)
    return decorated_function

@app.route('/', methods=['GET'])
def root():
    """Public root endpoint - no API key required"""
    return jsonify({
        'service': 'LaTeX Compiler API',
        'status': 'running',
        'version': '1.0.0',
        'message': 'Service is operational. Use /health or /compile endpoints with X-API-KEY header.',
        'endpoints': {
            'GET /': 'Service information (public)',
            'GET /health': 'Health check (requires API key)',
            'POST /compile': 'Compile LaTeX to PDF (requires API key)'
        },
        'usage': {
            'auth': 'Include X-API-KEY header with your API key',
            'compile': 'POST /compile with JSON: {"latex_content": "\\\\documentclass{article}..."}'
        }
    })

@app.route('/health', methods=['GET'])
@require_api_key
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy', 
        'service': 'latex-compiler',
        'timestamp': str(os.environ.get('TZ', 'UTC'))
    })

@app.route('/compile', methods=['POST'])
@require_api_key
def compile_latex():
    """Compile LaTeX content to PDF"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'JSON payload required'}), 400
            
        latex_content = data.get('latex_content', '')
        
        if not latex_content:
            return jsonify({'error': 'latex_content is required'}), 400
        
        # Create temporary directory for compilation
        with tempfile.TemporaryDirectory() as tmpdir:
            tex_file = os.path.join(tmpdir, 'document.tex')
            with open(tex_file, 'w', encoding='utf-8') as f:
                f.write(latex_content)
            
            # Run pdflatex
            result = subprocess.run(
                ['pdflatex', '-interaction=nonstopmode', 'document.tex'],
                cwd=tmpdir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            pdf_file = os.path.join(tmpdir, 'document.pdf')
            if os.path.exists(pdf_file):
                # Return PDF file
                with open(pdf_file, 'rb') as f:
                    pdf_content = f.read()
                return pdf_content, 200, {
                    'Content-Type': 'application/pdf',
                    'Content-Disposition': 'attachment; filename=document.pdf'
                }
            else:
                # Return compilation error
                return jsonify({
                    'error': 'LaTeX compilation failed',
                    'log': result.stdout + result.stderr,
                    'stderr': result.stderr,
                    'stdout': result.stdout
                }), 400
                
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Compilation timeout (30 seconds exceeded)'}), 408
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF

echo -e "${GREEN}✅ app.py fixed with root route${NC}"

# ========================================
# 4. FIX NGINX CONFIGURATION
# ========================================
echo -e "${BLUE}🔧 Step 4: Fixing nginx.conf...${NC}"

# Backup original nginx.conf
cp nginx.conf nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create Cloudflare-compatible nginx.conf
cat > nginx.conf << 'EOF'
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name latex-compiler.handjobs.co.in;
    
    # For Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Redirect all other HTTP requests to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server - Cloudflare compatible
server {
    listen 443 ssl http2;
    server_name latex-compiler.handjobs.co.in;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/latex-compiler.handjobs.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/latex-compiler.handjobs.co.in/privkey.pem;
    
    # Modern SSL configuration (Cloudflare compatible)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # Security headers (moderate - compatible with Cloudflare)
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Main application proxy
    location / {
        proxy_pass http://latex-compiler:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # Cloudflare headers
        proxy_set_header CF-Connecting-IP $http_cf_connecting_ip;
        proxy_set_header CF-Visitor $http_cf_visitor;
        proxy_set_header CF-Ray $http_cf_ray;
        
        # Timeouts and limits
        proxy_read_timeout 120s;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        client_max_body_size 50M;
        client_body_timeout 60s;
        
        # HTTP version and connection handling
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Health check endpoint for monitoring
    location /nginx-health {
        access_log off;
        return 200 "nginx is healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo -e "${GREEN}✅ nginx.conf fixed (Cloudflare compatible)${NC}"

# ========================================
# 5. CHECK DOMAIN AND IP
# ========================================
echo -e "${BLUE}🌐 Step 5: Checking domain and IP...${NC}"

echo "Domain resolution:"
nslookup latex-compiler.handjobs.co.in || echo "⚠️ Domain resolution issue"

echo ""
echo "Your server's public IP:"
SERVER_IP=$(curl -s ifconfig.me || echo "unknown")
echo "Server IP: $SERVER_IP"

echo ""
echo -e "${YELLOW}⚠️ IMPORTANT: If using Cloudflare proxy (orange cloud):${NC}"
echo "- Set SSL/TLS mode to 'Full (strict)' in Cloudflare dashboard"
echo "- Or disable proxy (grey cloud) and point A record to: $SERVER_IP"

# ========================================
# 6. OBTAIN SSL CERTIFICATES
# ========================================
echo -e "${BLUE}🔐 Step 6: Obtaining SSL certificates...${NC}"

certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email teamhandjobs.co.in@gmail.com \
    -d latex-compiler.handjobs.co.in \
    --force-renewal

# Verify SSL certificate
if test -f "/etc/letsencrypt/live/latex-compiler.handjobs.co.in/fullchain.pem"; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
    openssl x509 -in /etc/letsencrypt/live/latex-compiler.handjobs.co.in/fullchain.pem -noout -dates
else
    echo -e "${RED}❌ SSL certificate creation failed!${NC}"
    tail -20 /var/log/letsencrypt/letsencrypt.log
    exit 1
fi

# ========================================
# 7. BUILD AND DEPLOY
# ========================================
echo -e "${BLUE}🐳 Step 7: Building and deploying...${NC}"

# Build and start services
docker compose build --no-cache
docker compose up -d

echo -e "${GREEN}✅ Services deployed${NC}"

# ========================================
# 8. WAIT AND TEST
# ========================================
echo -e "${BLUE}⏳ Step 8: Waiting for services to start...${NC}"
sleep 20

echo -e "${BLUE}🧪 Step 9: Testing services...${NC}"

# Test HTTP (should redirect)
echo "Testing HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://latex-compiler.handjobs.co.in/ || echo "000")
echo "HTTP response: $HTTP_CODE"

# Test HTTPS
echo "Testing HTTPS..."
HTTPS_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://latex-compiler.handjobs.co.in/ || echo "000")
echo "HTTPS response: $HTTPS_CODE"

# Test with actual content
echo "Testing HTTPS with content..."
HTTPS_RESPONSE=$(curl -s -k https://latex-compiler.handjobs.co.in/ | head -c 100 || echo "no response")
echo "HTTPS content: $HTTPS_RESPONSE..."

# ========================================
# 9. SET UP AUTO-RENEWAL
# ========================================
echo -e "${BLUE}🔄 Step 10: Setting up SSL auto-renewal...${NC}"
(crontab -l 2>/dev/null | grep -v "certbot renew"; echo "0 12 * * * /usr/bin/certbot renew --quiet && cd $(pwd) && docker compose restart nginx") | crontab -
echo -e "${GREEN}✅ SSL auto-renewal configured${NC}"

# ========================================
# 10. SHOW STATUS AND RESULTS
# ========================================
echo ""
echo -e "${BLUE}📊 Service Status:${NC}"
docker compose ps

echo ""
echo -e "${BLUE}📋 Service Logs:${NC}"
echo "Nginx logs:"
docker compose logs nginx --tail=5
echo ""
echo "App logs:"
docker compose logs latex-compiler --tail=5

# ========================================
# 11. FINAL RESULTS
# ========================================
echo ""
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}======================${NC}"
echo ""

if [ "$HTTPS_CODE" = "200" ]; then
    echo -e "${GREEN}✅ SUCCESS! Service is running with HTTPS!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Service URLs:${NC}"
    echo "• Root:    https://latex-compiler.handjobs.co.in/"
    echo "• Health:  https://latex-compiler.handjobs.co.in/health (requires API key)"
    echo "• Compile: https://latex-compiler.handjobs.co.in/compile (requires API key)"
    echo ""
    echo -e "${BLUE}🔑 API Usage:${NC}"
    echo "Set X-API-KEY header with your API key from .env file"
    echo ""
    echo -e "${BLUE}📝 Example cURL commands:${NC}"
    echo "# Test root (no auth needed):"
    echo "curl https://latex-compiler.handjobs.co.in/"
    echo ""
    echo "# Test health (with API key):"
    echo "curl -H \"X-API-KEY: your-api-key\" https://latex-compiler.handjobs.co.in/health"
    echo ""
    echo "# Compile LaTeX (with API key):"
    echo "curl -X POST -H \"X-API-KEY: your-api-key\" -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"latex_content\": \"\\\\documentclass{article}\\\\begin{document}Hello World\\\\end{document}\"}' \\"
    echo "  https://latex-compiler.handjobs.co.in/compile --output document.pdf"
    
else
    echo -e "${RED}❌ HTTPS not working properly (Code: $HTTPS_CODE)${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Troubleshooting:${NC}"
    echo "1. Check if domain points to your server IP: $SERVER_IP"
    echo "2. If using Cloudflare, set SSL mode to 'Full (strict)'"
    echo "3. Check logs: docker compose logs"
    echo "4. Verify SSL: openssl s_client -connect latex-compiler.handjobs.co.in:443"
fi

echo ""
echo -e "${BLUE}📋 Maintenance:${NC}"
echo "• SSL certificate will auto-renew"
echo "• To restart: docker compose restart"
echo "• To check logs: docker compose logs"
echo "• To update: git pull && sudo ./deploy-production.sh"

echo ""
echo -e "${GREEN}🎯 Deployment script completed!${NC}"
