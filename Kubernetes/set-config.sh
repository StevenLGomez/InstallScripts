
# This group for Bmx OpenShift Sandbox
export USERNAME=bmxengineering
export CLUSTER_NAME=api-sandbox-m3-1530-p1-openshiftapps-com:6443
export CONTEXT=bmxengineering-dev/api-sandbox-m3-1530-p1-openshiftapps-com:6443/bmxengineering
export API_SERVER_URL=https://api.sandbox.m3.1530.p1.openshiftapps.com:6443

# The configuration steps
kubectl config set-credentials ${USERNAME}/${CLUSTER_NAME} --token=${TOKEN}
kubectl config set-cluster ${CLUSTER_NAME} --server=${API_SERVER_URL}
kubectl config set-context ${CONTEXT} --user=${USERNAME}/${CLUSTER_NAME} --namespace=${USERNAME}-dev --cluster=${CLUSTER_NAME}
kubectl config use-context ${CONTEXT}

