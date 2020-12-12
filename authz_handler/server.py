from flask import Flask, request
from kubernetes import KubernetesAuthzHandler


app = Flask(__name__)


@app.route('/', methods=['POST'])
def handle_authz():
    """Authorize all access requests
    
    Used to determine
    """
    authz_query = request.json
    handler = KubernetesAuthzHandler(authz_query["apiVersion"])
    return handler.handle_authz(authz_query)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8005, ssl_context=('../pki/moon-pdp.crt', '../pki/moon-pdp.key'), debug=True)
