
function deploy_configmap_fromfile () {
if [ -f "$2" ] || [ -d $2 ]; then 
  kubectl create configmap $1 --from-file=$2 -o yaml --dry-run=client | kubectl replace -f - || kubectl create configmap $1 --from-file=$2
fi
}

function deploy_yaml () {
if [ -f "$1" ]; then 
  kubectl apply -f $1 -o yaml --dry-run=client | kubectl replace -f - || kubectl apply -f $1
fi
}

deploy_configmap_fromfile nginx-default ./nginx/default.conf
deploy_configmap_fromfile nginx-index ./nginx/index.html
deploy_yaml yaml/headless-service.yaml

deploy_configmap_fromfile haproxy-config ./haproxy/haproxy.cfg
deploy_configmap_fromfile haproxy-modsecurity ./haproxy/spoe-modsecurity.conf
deploy_yaml yaml/testhaproxy.yaml

deploy_configmap_fromfile modsecurity-default ./modsecurity
deploy_configmap_fromfile modsecurity-rules ./modsecurity/rules
deploy_yaml yaml/modsecurity-spoa.yaml
