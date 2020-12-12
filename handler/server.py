from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return "hello"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8005, ssl_context=('../pki_v2/ca.crt', '../pki_v2/ca.key'), debug=True)
