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

@app.route('/health', methods=['GET'])
@require_api_key
def health():
    return jsonify({'status': 'healthy', 'service': 'latex-compiler'})

@app.route('/compile', methods=['POST'])
@require_api_key
def compile_latex():
    try:
        data = request.get_json()
        latex_content = data.get('latex_content', '')
        
        if not latex_content:
            return jsonify({'error': 'latex_content is required'}), 400
        
        with tempfile.TemporaryDirectory() as tmpdir:
            tex_file = os.path.join(tmpdir, 'document.tex')
            with open(tex_file, 'w') as f:
                f.write(latex_content)
            
            result = subprocess.run(
                ['pdflatex', '-interaction=nonstopmode', 'document.tex'],
                cwd=tmpdir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            pdf_file = os.path.join(tmpdir, 'document.pdf')
            if os.path.exists(pdf_file):
                with open(pdf_file, 'rb') as f:
                    pdf_content = f.read()
                return pdf_content, 200, {'Content-Type': 'application/pdf'}
            else:
                return jsonify({
                    'error': 'Compilation failed',
                    'log': result.stdout + result.stderr
                }), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
