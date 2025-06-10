#!/bin/bash

# LaTeX Compiler HTTPS Deployment Script
# Simple one-command deployment with Docker Compose

set -e

echo "🚀 Deploying LaTeX Compiler with HTTPS..."

# 1. Update system and install Docker
echo "📦 Installing Docker and dependencies..."
sudo apt update
sudo apt install -y docker.io docker-compose-v2 nginx certbot
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# 2. Generate API key if not exists
if [ ! -f .env ]; then
    echo "🔐 Generating secure API key..."
    API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    echo "API_KEY=$API_KEY" > .env
    chmod 600 .env
    echo "✅ API key generated: $API_KEY"
else
    echo "✅ Using existing API key from .env"
fi

# 3. Setup SSL certificate
echo "🔒 Setting up SSL certificate for latex-compiler.handjobs.co.in..."
echo "⚠️  IMPORTANT: Make sure your DNS points to this server IP: $(curl -s ifconfig.me)"
echo "   Add A record: latex-compiler.handjobs.co.in -> $(curl -s ifconfig.me)"
read -p "Press Enter when DNS is configured..."

# Stop nginx if running to free port 80
sudo systemctl stop nginx 2>/dev/null || true

# Get SSL certificate
sudo certbot certonly --standalone \
    -d latex-compiler.handjobs.co.in \
    --email teamhandjobs.co.in@gmail.com \
    --agree-tos --non-interactive

# 4. Start services with Docker Compose
echo "🚀 Starting services with Docker Compose..."
sudo docker compose down 2>/dev/null || true
sudo docker compose up -d --build

# 5. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# 6. Test the service
echo "🧪 Testing HTTPS service..."
source .env
if curl -s -k -H "X-API-KEY: $API_KEY" https://latex-compiler.handjobs.co.in/health > /dev/null; then
    echo "✅ Service is running successfully with HTTPS!"
    echo ""
    echo "🌐 Service URL: https://latex-compiler.handjobs.co.in"
    echo "🔑 API Key: $API_KEY"
    echo ""
    echo "📝 Test commands:"
    echo "curl -H \"X-API-KEY: $API_KEY\" https://latex-compiler.handjobs.co.in/health"
    echo ""
    echo "📋 Management commands:"
    echo "  Status: sudo docker compose ps"
    echo "  Logs: sudo docker compose logs -f"
    echo "  Stop: sudo docker compose down"
    echo "  Restart: sudo docker compose restart"
else
    echo "❌ HTTPS test failed. Checking logs..."
    echo "📋 Check status:"
    sudo docker compose ps
    echo ""
    echo "📋 Check logs:"
    sudo docker compose logs --tail=20
fi

echo "🎉 Deployment complete!"