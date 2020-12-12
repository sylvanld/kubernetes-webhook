from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def handle_authz():
    print(request.json)
    print('kind', request.json['kind'])
    print('api_version', request.json['apiVersion'])
    return {
        "apiVersion": "authorization.k8s.io/v1beta1",
        "kind": "SubjectAccessReview",
        "status": {
            "allowed": True
        }
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8005, ssl_context=('../pki/moon-pdp.crt', '../pki/moon-pdp.key'), debug=True)
