#!/bin/bash

docker run -v ~/.kube:/home/argocd/.kube --rm quay.io/argoproj/argocd:v2.11.5 argocd admin export -n argocd > argo_backup.yaml
