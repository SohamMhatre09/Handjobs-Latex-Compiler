#!/bin/bash
# setup_latex_vm.sh - Setup script for LaTeX Compiler VM

echo "🚀 Setting up LaTeX Compiler VM"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    
    # Update package index
    sudo apt update
    
    # Install dependencies
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt update
    
    # Install Docker
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully"
    echo "⚠️  Please log out and log back in for group changes to take effect"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Installing Docker Compose..."
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose installed successfully"
fi

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p logs

# Build and start the LaTeX compiler service
echo "🔧 Building LaTeX compiler Docker image..."
docker-compose build

echo "🚀 Starting LaTeX compiler service..."
docker-compose up -d

# Wait for service to be ready
echo "⏳ Waiting for LaTeX compiler to be ready..."
sleep 30

# Test the service
echo "🧪 Testing LaTeX compiler service..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)

if [ "$response" = "200" ]; then
    echo "✅ LaTeX compiler service is healthy!"
    
    # Run test compilation
    echo "🧪 Testing LaTeX compilation..."
    test_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/test)
    
    if [ "$test_response" = "200" ]; then
        echo "✅ LaTeX compilation test passed!"
    else
        echo "⚠️  LaTeX compilation test failed (status: $test_response)"
    fi
else
    echo "❌ LaTeX compiler service is not responding (status: $response)"
    echo "📊 Checking service logs..."
    docker-compose logs latex-compiler
fi

echo ""
echo "🎉 LaTeX Compiler VM Setup Complete!"
echo ""
echo "📋 Service Information:"
echo "   • Health Check: http://localhost:8080/health"
echo "   • Compilation Endpoint: http://localhost:8080/compile"
echo "   • Test Endpoint: http://localhost:8080/test"
echo ""
echo "🔍 Useful Commands:"
echo "   • Check status: docker-compose ps"
echo "   • View logs: docker-compose logs -f"
echo "   • Stop service: docker-compose down"
echo "   • Restart service: docker-compose restart"
echo ""
echo "💡 Make sure to configure your main backend to use:"
echo "   LATEX_COMPILER_URL=http://YOUR_VM_IP:8080/compile"
