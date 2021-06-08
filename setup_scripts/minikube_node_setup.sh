#!/usr/bin/env bash

ARG1=${1:-"127.0.0.1:8080"}

# start minikube
minikube start

# install arkade
curl -SLsf https://dl.get-arkade.dev/ | sudo sh

# install OpenFaaS using arkade
arkade install openfaas

# export OpenFaaS URL
export OPENFAAS_URL=$ARG1

# add bitnami repo to helm
helm repo add bitnami https://charts.bitnami.com/bitnami

# install bitnami mongodb
helm install bitnami/mongodb openfaas-db \
  --namespace openfaas-fn \
  --set persistence.enabled=false

