# LaTeX Compiler Service
# This service runs on a separate VM instance with full LaTeX packages installed

from flask import Flask, request, jsonify
import subprocess
import tempfile
import os
import shutil
import logging
from datetime import datetime
from functools import wraps

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Security configuration
API_KEY = os.environ.get('API_KEY', 'djsakjc213hjbkk3h123jkb123kbj')

@app.after_request
def after_request(response):
    """Add security headers to all responses"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['Server'] = 'LaTeX-Compiler-Service'
    return response

def require_api_key(f):
    """Decorator to require API key authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check for API key in headers
        api_key = request.headers.get('X-API-KEY')
        
        if not api_key:
            logger.warning(f"Missing API key from {request.remote_addr}")
            return jsonify({'error': 'API key required', 'message': 'X-API-KEY header is required'}), 401
        
        if api_key != API_KEY:
            logger.warning(f"Invalid API key from {request.remote_addr}: {api_key[:10]}...")
            return jsonify({'error': 'Invalid API key', 'message': 'The provided API key is not valid'}), 403
        
        logger.info(f"Authenticated request from {request.remote_addr}")
        return f(*args, **kwargs)
    
    return decorated_function

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'latex-compiler', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/compile', methods=['POST'])
@require_api_key
def compile_latex():
    """Compile LaTeX content to PDF"""
    try:
        data = request.json
        latex_content = data.get('latex_content')
        timeout = data.get('timeout', 30)
        
        if not latex_content:
            return jsonify({'error': 'No LaTeX content provided'}), 400
        
        logger.info(f"Compiling LaTeX document, content length: {len(latex_content)} characters")
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write LaTeX content to file
            tex_file = os.path.join(temp_dir, 'resume.tex')
            with open(tex_file, 'w', encoding='utf-8') as f:
                f.write(latex_content)
            
            # First pass: Compile LaTeX to PDF
            result = subprocess.run([
                'pdflatex', 
                '-interaction=nonstopmode',
                '-output-directory', temp_dir,
                tex_file
            ], capture_output=True, text=True, cwd=temp_dir, timeout=timeout)
            
            # Second pass: Handle references and citations if needed
            if result.returncode == 0:
                # Run pdflatex again for proper cross-references
                result2 = subprocess.run([
                    'pdflatex', 
                    '-interaction=nonstopmode',
                    '-output-directory', temp_dir,
                    tex_file
                ], capture_output=True, text=True, cwd=temp_dir, timeout=timeout)
                
                if result2.returncode == 0:
                    result = result2  # Use second pass result
            
            pdf_file = os.path.join(temp_dir, 'resume.pdf')
            
            if os.path.exists(pdf_file) and result.returncode == 0:
                with open(pdf_file, 'rb') as f:
                    pdf_data = f.read()
                
                logger.info(f"Successfully compiled PDF, size: {len(pdf_data)} bytes")
                return pdf_data, 200, {
                    'Content-Type': 'application/pdf',
                    'Content-Disposition': 'attachment; filename=resume.pdf'
                }
            else:
                logger.error(f"PDF generation failed. Return code: {result.returncode}")
                logger.error(f"LaTeX output: {result.stdout}")
                logger.error(f"LaTeX errors: {result.stderr}")
                
                return jsonify({
                    'error': 'PDF generation failed',
                    'latex_output': result.stdout[-1000:] if result.stdout else '',  # Last 1000 chars
                    'latex_errors': result.stderr[-1000:] if result.stderr else '',   # Last 1000 chars
                    'return_code': result.returncode
                }), 500
                
    except subprocess.TimeoutExpired:
        logger.error("LaTeX compilation timed out")
        return jsonify({'error': f'LaTeX compilation timed out after {timeout} seconds'}), 408
    except Exception as e:
        logger.error(f"Unexpected error during compilation: {str(e)}")
        return jsonify({'error': f'Compilation error: {str(e)}'}), 500

@app.route('/test', methods=['POST'])
@require_api_key
def test_compile():
    """Test endpoint with minimal LaTeX document"""
    test_latex = r"""
\documentclass{article}
\begin{document}
\title{Test Document}
\author{LaTeX Compiler}
\date{\today}
\maketitle

This is a test document to verify LaTeX compilation is working.

\section{Test Section}
LaTeX compiler is working correctly!

\end{document}
"""
    
    try:
        # Simulate the compile request
        fake_request = type('obj', (object,), {'json': {'latex_content': test_latex}})
        request_backup = request
        
        # Temporarily replace request
        import builtins
        builtins.request = fake_request
        
        response = compile_latex()
        
        # Restore original request
        builtins.request = request_backup
        
        if isinstance(response, tuple) and response[1] == 200:
            return jsonify({'status': 'success', 'message': 'LaTeX compilation test passed'}), 200
        else:
            return jsonify({'status': 'failed', 'message': 'LaTeX compilation test failed'}), 500
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    # Check if LaTeX is installed
    try:
        result = subprocess.run(['pdflatex', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            logger.info("LaTeX installation verified")
            logger.info(f"pdflatex version: {result.stdout.split()[0] if result.stdout else 'Unknown'}")
        else:
            logger.error("LaTeX not properly installed")
    except FileNotFoundError:
        logger.error("pdflatex command not found. Please install LaTeX.")
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=8080, debug=False)
