import os
import json
import argparse
import requests


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='localhost', help='Address on which kubernetes apiserver listen')
    parser.add_argument('--port', default=6443, help='Port on which kubernetes apiserver listen')
    parser.add_argument('--apiversion', default='rbac.authorization.k8s.io/v1beta1', help='Authorization plugin')
    args = parser.parse_args()
    return args


def list_resources(host, port, api_version):
    authorization_url = 'https://%s:%s/apis/%s'%(host, port, api_version)
    response = requests.get(authorization_url, verify=False)
    for resource in response.json()["resources"]:
        with open(os.path.join('../policies', resource['name'] + '.json'), 'w') as resource_file:
            response2 = requests.get(authorization_url + '/' + resource['name'], verify=False)
            resource_policies = response2.json()
            json.dump(resource_policies, resource_file, indent=4)

def main():
    args = parse_args()
    resources = list_resources(args.host, args.port, args.apiversion)
    print(resources)
    


if __name__ == '__main__':
    main()