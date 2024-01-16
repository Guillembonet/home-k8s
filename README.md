# home-k8s

## Proxy

The purpose of the proxy is to hide your home IP by proxying all from any other machine. It also reduces complexity of the setup by connecting to the cluster nodes using Wireguard, which eliminates any need to forward any ports.

### Requirements:

- Wireguard
- Docker and Docker Compose

### Deployment steps:

1. Make sure ports 80/TCP, 443/TCP and 6443/TCP are accessible.
2. Generate a Wireguard private key and paste it to proxy/k8s-tunnel.conf `<private_key>`.
    ```
    wg genkey
    ```
3. Set a port in proxy/k8s-tunnel.conf (make sure that the port is open in the machine too).

4. Set peer public key in proxy/k8s-tunnel.conf `<peer_public_key>`. Get it with this command:
    ```
    echo "<peer_private_key>" | wg pubkey
    ```
5. Copy Wireguard config to `/etc/wireguard`.
    ```
    cp ./proxy/k8s-tunnel.conf /etc/wireguard/k8s-tunnel.conf
    ```
6. Add Wireguard tunnel to systemd and start it.
    ```
    sudo systemctl enable wg-quick@k8s-tunnel.service
    sudo systemctl daemon-reload
    sudo systemctl start wg-quick@k8s-tunnel
    ```
7. Start proxies with Docker Compose.
    ```
    docker compose up -d
    ```

## Initial cluster deployment

1. Install k3s (with optional extra tls-san)
    ```
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --tls-san <namespace>" sh -
    ```
2. Add agent nodes

### Additional node configuration

1. Generate a Wireguard private key and paste it to k8s/k8s-tunnel.conf `<private_key>`.
    ```
    wg genkey
    ```
2. Set endpoint in k8s/k8s-tunnel.conf `<server_ip_or_hostname>:<server_port>`.

3. Set peer public key in k8s/k8s-tunnel.conf `<peer_public_key>`. Get it with this command:
    ```
    echo "<peer_private_key>" | wg pubkey
    ```
4. Copy Wireguard config to `/etc/wireguard`.
    ```
    cp ./k8s-tunnel.conf /etc/wireguard/k8s-tunnel.conf
    ```
5. Add Wireguard tunnel to systemd and start it.
    ```
    sudo systemctl enable wg-quick@k8s-tunnel.service
    sudo systemctl daemon-reload
    sudo systemctl start wg-quick@k8s-tunnel
    ```

## Cluster configuration

### Dependencies:

- open-iscsi

### Steps:

1. Install Longhorn using helm.
    ```
    kubectl apply -f ./k8s/longhorn/0_namespace.yaml
    helm install longhorn ./k8s/longhorn --namespace longhorn --values ./k8s/longhorn/values.yaml
    ```

2. Configure Traefik and add middleware.
    ```
    helm upgrade traefik ./k8s/traefik --namespace kube-system
    kubectl apply -f ./k8s/traefik/deny-metrics-middleware.yaml
    ```

3. Depoly cert-manager and issuer (needs configuration for the issuer).
    ```
    kubectl apply -f ./k8s/cert-manager/0_namespace.yaml
    helm install cert-manager ./k8s/cert-manager --namespace cert-manager --set installCRDs=true
    kubectl apply -f ./k8s/cert-manager/issuer.yaml
    ```

4. Install Prometheus using helm.
    ```
    kubectl apply -f ./k8s/prometheus/0_namespace.yaml
    helm install prometheus ./k8s/prometheus --namespace prometheus
    ```

5. Install Grafana using helm.
    ```
    kubectl apply -f ./k8s/grafana/0_namespace.yaml
    helm install grafana ./k8s/grafana --namespace grafana
    kubectl apply -f ./k8s/grafana/ingress.yaml
    ```

6. Install Argocd using helm.
    ```
    kubectl apply -f ./k8s/argo-cd/0_namespace.yaml
    helm install argocd ./k8s/argo-cd --namespace argocd
    ```

7. Install Sealed Secrets using helm.
    ```
    helm install sealed-secrets ./k8s/sealed-secrets --set-string fullnameOverride=sealed-secrets-controller --namespace kube-system
    ```

8.  Change all default passwords.