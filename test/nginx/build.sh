#!/bin/bash

cd $(dirname $0)
kubectl create configmap nginx-default --from-file=./default.conf
kubectl create configmap nginx-index --from-file=./index.html
kubectl apply -f ./testlb.yaml
