# home-k8s

## Deployment:

### Dependencies:

- open-iscsi

### Steps:

1. Install `open-iscsi`:
```
apt install open-iscsi -y
```

2. Install Longhorn using helm:
```
kubectl apply -f ./k8s/longhorn/0_namespace.yaml
helm install longhorn ./k8s/longhorn --namespace longhorn --values ./k8s/longhorn/values.yaml
```

3. Install Prometheus using helm:
```
kubectl apply -f ./k8s/prometheus/0_namespace.yaml
helm install prometheus ./k8s/prometheus --namespace prometheus
```

4. Install Grafana using helm:
```
kubectl apply -f ./k8s/grafana/0_namespace.yaml
helm install grafana ./k8s/grafana --namespace grafana
```

5. Install Argocd using helm:
```
kubectl apply -f ./k8s/argo-cd/0_namespace.yaml
helm install argocd ./k8s/argo-cd --namespace argocd
```

6. Install Sealed Secrets using helm:
```
helm install sealed-secrets ./k8s/sealed-secrets --set-string fullnameOverride=sealed-secrets-controller --namespace kube-system
```

7. Change all default passwords