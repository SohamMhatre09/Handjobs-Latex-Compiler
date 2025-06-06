# Dockerfile for LaTeX Compiler Service (Production Ready)
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set production environment variables
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1
ENV API_KEY=djsakjc213hjbkk3h123jkb123kbj

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-english \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Create log directories
RUN mkdir -p /var/log/gunicorn /app/logs && \
    chown -R appuser:appuser /var/log/gunicorn /app/logs

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check with API key
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f -H "X-API-KEY: $API_KEY" http://localhost:8080/health || exit 1

# Run the production application
CMD ["./start_production.sh"]
