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
