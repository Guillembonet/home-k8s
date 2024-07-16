# home-k8s

This repository contains the configuration files for a home lab Kubernetes cluster. A detailed explanation of the setup can be found in [my blog post](https://bunetz.dev/blog/posts/how-i-over-engineered-my-cluster-part-1).

## Proxy

The purpose of the proxy is to hide your home IP by proxying all from any other machine. It also reduces complexity of the setup by connecting to the cluster nodes using Wireguard, which eliminates any need to forward any ports.

### Requirements:

- Wireguard
- Docker and Docker Compose

### Deployment steps:

1. Make sure ports 80/TCP, 443/TCP, 8080/TCP and 6443/TCP are accessible.
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

1. Install k3s (with some configurations):
    ```
    curl -sfL https://get.k3s.io | sh -s - --tls-san bunetz.dev --tls-san 192.168.1.4 --disable=traefik --advertise-address=10.1.10.1 --node-ip=10.1.10.1 --flannel-iface=k8s-tunnel
    ```
2. Add agent nodes:
   ```
   curl -sfL https://get.k3s.io | K3S_URL=https://10.1.10.1:6443 K3S_TOKEN=<token> sh -s - --node-ip=10.1.10.3 --flannel-iface=k8s-tunnel
   ```

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
- latest linux kernel headers and modules extra (for Raspberry Pi ubuntu server). See `post_update_pre_restart.sh` script.

### Steps:

1. Install Argocd using helm.
    ```
    kubectl apply -f ./k8s/argocd-config/0_namespace.yaml
    helm repo add argo https://argoproj.github.io/argo-helm
    helm install -f ./k8s/helm-charts/argocd-values.yaml argocd argo/argo-cd --namespace argocd --version 7.3.7
    ```

2. Port forward the argocd server, login using generated password and start adding apps to argocd. Start with `helm-charts` which will add all the helm charts and sync it, which will create the application resources (without deploying them). Then start by syncing the argocd helm applications, start with `sealed-secrets` so secrets can be decrypted, and make sure to sync Longhorn before adding any app which requires persistent storage.

3. Change all default passwords.