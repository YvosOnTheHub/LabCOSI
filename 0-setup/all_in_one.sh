echo "############################################"
echo "# Install Tools"
echo "############################################"
apt update
apt install -y snapd jq ansible-core docker
snap install kubectl --classic
snap install helm --classic
snap install aws-cli --classic
systemctl enable --now docker

echo "############################################"
echo "# Customize Ansible"
echo "############################################"

ansible-galaxy collection install git+https://github.com/ansible-collections/netapp.ontap.git --ignore-certs
ansible-galaxy collection install ansible.windows --ignore-certs --force

mkdir -p /etc/ansible
cat <<EOT > /etc/ansible/hosts
---
all:  
  vars: 
    hostname: 192.168.0.103
    username: admin 
    password: Netapp1!
EOT

echo "############################################"
echo "# Install KinD and create a cluster"
echo "############################################"

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

kind create cluster --name cosi-k8s --image kindest/node:v1.36.1
echo "Waiting for the cluster to be ready..."
until kubectl get nodes >/dev/null 2>&1; do
    sleep 1
done
echo "Cluster ready!"

echo "############################################"
echo "# Install Trident"
echo "############################################"

helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
helm upgrade --install trident netapp-trident/trident-operator --version 100.2610.0 -n trident \
--set imageRegistry=quay.io/yvosonthehub/sig-storage \
--set tridentAutosupportImage=quay.io/yvosonthehub/netapp/trident-autosupport:26.10.0 \
--set operatorImage=quay.io/yvosonthehub/netapp/trident-operator:26.10.0 \
--set tridentImage=quay.io/yvosonthehub/netapp/trident:26.10.0 \
--set enableConcurrency=true \
--set enableCOSI=true

echo
echo "#######################################################################################################"
echo "Wait for Trident to be ready"
echo "#######################################################################################################"
echo

frames="/ | \\ -"
until kubectl get crd tridentversions.trident.netapp.io >/dev/null 2>&1; do
    for frame in $frames; do
        sleep 0.5; printf "\rWaiting for CRD tridentversions.trident.netapp.io $frame"
    done
done
echo
until [ "$(kubectl get tver trident -n trident -o jsonpath='{.trident_version}' 2>/dev/null)" = "26.10.0" ]; do
    for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready $frame"
    done
done
echo
while true; do
    # Count every pod & those not yet Running with all their containers ready,
    # so the wait works whatever the number of nodes (Windows nodes or not).
    pod_state=$(kubectl get -n trident pod --no-headers 2>/dev/null | awk '
        { total++; split($2, ready, "/"); if ($3 != "Running" || ready[1] != ready[2]) pending++ }
        END { print total+0, pending+0 }')
    total=${pod_state% *}
    pending=${pod_state#* }
    if [ "$total" -gt 0 ] && [ "$pending" -eq 0 ]; then break; fi
    for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready [$((total - pending))/$total pods] $frame"
    done
done


echo
echo "#######################################################################################################"
echo "Customize Bash"
echo "#######################################################################################################"
echo

cp ~/.bashrc ~/.bashrc.bak
cat <<EOT >> ~/.bashrc
alias k=kubectl
alias kc=kubectl create
alias kg=kubectl get
alias kd=kubectl describe
alias kdel=kubectl delete
alias kedit=kubectl edit
alias kx=kubectl exec -it
alias trident=tridentctl -n trident
EOT
echo "Bash customized!"
