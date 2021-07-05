kubectl create configmap nginx-default --from-file=/vagrant/test/haproxy/default.conf -o yaml --dry-run=client | kubectl replace -f - || kubectl create configmap nginx-default --from-file=/vagrant/test/haproxy/default.conf
kubectl create configmap nginx-index --from-file=/vagrant/test/haproxy/index.html -o yaml --dry-run=client | kubectl replace -f - || kubectl create configmap nginx-index --from-file=/vagrant/test/haproxy/index.html
kubectl apply -f headless-service.yaml -o yaml --dry-run=client | kubectl replace -f - || kubectl apply -f headless-service.yaml

kubectl apply -f testhaproxy.yaml -o yaml --dry-run=client | kubectl replace -f - || kubectl create configmap haproxy-config --from-file=./haproxy.cfg
kubectl apply -f testhaproxy.yaml -o yaml --dry-run=client | kubectl replace -f - || kubectl apply -f testhaproxy.yaml
