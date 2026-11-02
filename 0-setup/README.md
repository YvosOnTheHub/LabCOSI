#########################################################################################
# Lab setup (**to run on the host Ubuntu**)
#########################################################################################

The purpose of the lab being to test COSI, no need for a fancy Kubernetes cluster, let's create a KinD cluster (Kubernetes in Docker).  

You can also use the *all_in_one.sh* script in this folder to perform all those tasks for you.  

### Install Tools

We first need to install all the tools required for the demos (docker, kubectl, aws-cli, ...)
```bash
apt update
apt install -y snapd jq ansible-core docker
snap install kubectl --classic
snap install helm --classic
snap install aws-cli --classic
systemctl enable --now docker
```

### Customize Ansible

You will use Ansible to create a new SVM. This will require some specific collections (ONTAP, Windows):  
```bash
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
```

### Install KinD and create a cluster

COSI requires Kubernetes 1.32 minimum. Let's install 1.36 which is more recent:  
```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

kind create cluster --name cosi-k8s --image kindest/node:v1.36.1
kubectl cluster-info --context kind-cosi-k8s
```

### Install Trident

First, let's get the Tridentctl binary:  
```bash
wget https://github.com/NetApp/trident/releases/download/v26.10.0/trident-installer-26.10.0.tar.gz -O ~/trident-installer-26.10.0-custom.tar.gz
tar -xf trident-installer-26.10.0.tar.gz
rm -f /usr/local/bin/tridentctl
cp ~/trident-installer/tridentctl /usr/local/bin/
```
Trident can be installed with a Helm chart.  
To avoid any issues with docker limit rates, we can use a mirror repo:    
```bash
helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
helm upgrade --install trident netapp-trident/trident-operator --version 100.2610.0 -n trident \
--set tridentAutosupportImage=quay.io/yvosonthehub/netapp/trident-autosupport:26.10.0 \
--set operatorImage=quay.io/yvosonthehub/netapp/trident-operator:26.10.0 \
--set tridentImage=quay.io/yvosonthehub/netapp/trident:26.10.0 \
--set enableConcurrency=true \
--set enableCOSI=true
```
After a couple of minutes, you can see the following in the Trident namespace:  
```bash
$ kubectl get -n trident po
NAME                                 READY   STATUS    RESTARTS   AGE
trident-controller-cbc9dcf6d-sv669   6/6     Running   0          24s
trident-node-linux-844fz             2/2     Running   0          24s
trident-operator-685ff765c6-bsw58    1/1     Running   0          62s
```
Validate that both concurrency and COSI are enabled:  
```bash
$ kubectl get -n trident po -l app=controller.csi.trident.netapp.io -o yaml | grep concur -A 1
      - --enable_concurrency=true
      - --enable_cosi=true
```

You are now ready to try COSI, move on to one of the following:  
- [1 - StorageGRID](../1-storagegrid/)
- [2 - ONTAP](../2-ontap/)