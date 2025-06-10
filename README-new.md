# LaTeX Compiler Service

Simple Docker-based LaTeX to PDF compiler service with HTTPS and API key authentication.

## 🚀 One-Command Deploy

### Step 1: Configure DNS in Cloudflare
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select your domain `handjobs.co.in`
3. Go to **DNS** → **Records**
4. Add **A Record**:
   - **Type:** A
   - **Name:** `latex-compiler`
   - **IPv4 Address:** [Your server IP]
   - **Proxy Status:** 🟠 **ON** (Orange Cloud)

### Step 2: Deploy Everything
Run this on a fresh Ubuntu VM:

```bash
chmod +x deploy.sh
./deploy.sh
```

**That's it!** The script will handle everything:
- Install Docker and dependencies
- Generate secure API key
- Get SSL certificate from Let's Encrypt
- Build and start services with Docker Compose
- Test HTTPS endpoints automatically

## 📋 API Endpoints

Base URL: `https://latex-compiler.handjobs.co.in`

### Health Check
- **Endpoint:** `GET /health`
- **Headers:** `X-API-KEY: your-api-key`
- **Response:** `{"status": "healthy", "service": "latex-compiler"}`

### Compile LaTeX
- **Endpoint:** `POST /compile`
- **Headers:** 
  - `Content-Type: application/json`
  - `X-API-KEY: your-api-key`
- **Input:**
  ```json
  {
    "latex_content": "\\documentclass{article}\\begin{document}Hello World\\end{document}"
  }
  ```
- **Output:** PDF file (binary)

## 🔧 Usage Examples

### Health Check
```bash
source .env
curl -H "X-API-KEY: $API_KEY" https://latex-compiler.handjobs.co.in/health
```

### Compile Document
```bash
source .env
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $API_KEY" \
  -d '{"latex_content": "\\documentclass{article}\\begin{document}Hello World\\end{document}"}' \
  https://latex-compiler.handjobs.co.in/compile \
  --output document.pdf
```

## 🛠 Management

### Check Status
```bash
sudo docker compose ps
```

### View Logs
```bash
sudo docker compose logs -f
```

### Restart
```bash
sudo docker compose restart
```

### Stop
```bash
sudo docker compose down
```

## 🔑 API Key

Your API key is in the `.env` file:
```bash
cat .env
```

## 📊 Requirements

- Ubuntu 20.04+ VM
- 2GB+ RAM
- 2+ CPU cores
- 5GB+ disk space
