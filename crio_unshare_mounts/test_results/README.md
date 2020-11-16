# Testing

    podman run -ti -e KUBECONFIG=/auth/kubeconfig -v /root/ocp/auth/kubeconfig:/auth/kubeconfig registry.redhat.io/openshift4/ose-tests:latest openshift-tests run openshift/conformance/parallel | tee parallel.out
    podman run -ti -e KUBECONFIG=/auth/kubeconfig -v /root/ocp/auth/kubeconfig:/auth/kubeconfig registry.redhat.io/openshift4/ose-tests:latest openshift-tests run openshift/conformance/serial | tee serial.out

