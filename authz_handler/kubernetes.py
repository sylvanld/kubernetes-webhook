import json

class KubernetesAuthzBaseHandler:
    def __get_subject(self, payload):
        return payload["spec"]["user"]

    def __get_object(self, payload):
        return payload["spec"]["nonResourceAttributes"]["path"]

    def __get_action(self, payload):
        return payload["spec"]["nonResourceAttributes"]["verb"]

    def __make_response(self, authorize=False):
        return {
            "apiVersion": "authorization.k8s.io/v1beta1",
            "kind": "SubjectAccessReview",
            "status": {
                "allowed": authorize
            }
        }

    def handle_authz(self, payload):
        try:
            print('authz', json.dumps({
                'subject': self.__get_subject(payload),
                'object': self.__get_object(payload),
                'action': self.__get_action(payload)
            }, indent=4))
        except KeyError:
            pass
        
        return self.__make_response(True)


class KubernetesAuthzV1Beta1Handler(KubernetesAuthzBaseHandler):
    """
    Might be used later to handle apiVersion specific behaviour
    """


class KubernetesAuthzHandler:
    def __new__(cls, api_version):
        if api_version == "authorization.k8s.io/v1beta1":
            return KubernetesAuthzV1Beta1Handler()
        else:
            raise Exception("Unsupported kubernetes apiVersion: %s" % api_version)

