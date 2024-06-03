## Add dedicated user and token

We'll add a dedicated user `capmox` and assign it `PVEDatastoreAdmin`, `PVESDNUser`, and `PVEVMAdmin` roles:

*Note: Some capmox docs *

```bash
pveum user add capmox@pve
pveum aclmod / -user capmox@pve -role PVEDatastoreAdmin
pveum aclmod / -user capmox@pve -role PVESDNUser
pveum aclmod / -user capmox@pve -role PVEVMAdmin
pveum user token add capmox@pve capi -privsep 0
```

## Building Image for CAPI

Clone the Kubernetes sigs image-builder repo:

```bash
git clone https://github.com/kubernetes-sigs/image-builder.git
```

If you already have packer installed, you may need to downgrade to the release
prior to hashicorp switching to BSL license. It'll likely be v1.9.5, but you can
easily find out which version you need by viewing the [image-builder/images/capi/hack/ensure-packer.sh](https://github.com/kubernetes-sigs/image-builder/blob/896c21a8414810aa53751c7cc7be42b719c666c6/images/capi/hack/ensure-packer.sh#L23C1-L24C17) file.

```bash
sudo apt purge -y packer
```

The afforementioned `ensure-packer.sh` script from image-builder can actually download the
correct packer version for you. It will be executed when building the prereqs for your particular
virtualization platform. In this case, I am using proxmox so I will run the following from inside the cloned `image-builder` repo:

```bash
make deps-proxmox
```

The appropriate version of the packer binary should be located inside your local `image-builder` 
repo at the path `images/capi/.local/bin/packer`. You can either append the absolute path to your PATH
env variable or just move the packer binary to the `/usr/bin` directory.

You'll now need to have the following env variables exported:

```bash
export PROXMOX_URL="https://homex10.local.zachary.day:8006/api2/json"
export PROXMOX_USERNAME="capmox@pve!capi"
export PROXMOX_TOKEN="<replace-me>"
export PROXMOX_NODE="homex10"
export PROXMOX_ISO_POOL="pve-templates"
export PROXMOX_BRIDGE="vmbr0"
export PROXMOX_STORAGE_POOL="pve-disks"
```

Now we can build the image:

```bash
make build-proxmox-ubuntu-2404
```

## Setup Management Cluster

Fastest way is to spin up an ubuntu vm with microk8s installed.

You'll have to swap out things like hostnames/users/etc.

SSH into the new ubuntu vm running microk8s and add your user to the microk8s group:

```bash
sudo usermod -a -G microk8s capi
mkdir ~/.kube
sudo chown -R capi ~/.kube
microk8s config > ~/.kube/config
exit
```

Then copy over the kubeconfig file to local machine via scp:

```bash
scp capi@home-capi.local.zachary.day:/home/capi/.kube/config ./kubeconfig
```

Afterwards, I would recommend changing the cluster & context name in the copied kubeconfig file.

Then backup existing kubeconfig and merge it with the additional config for the management cluster:

```bash
KUBECONFIG="./kubeconfig:/home/dirichlet/.kube/config" k config view --flatten > merged
mv ~/.kube/config ~/.kube/config.bak
mv ./merged ~/.kube/config
```

## Add the in-cluster IPAM provider to clusterctl config

```bash
nano $XDG_CONFIG_HOME/cluster-api/clusterctl.yaml
```

```yaml
providers:
- name: in-cluster
  url: https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster/releases/latest/ipam-components.yaml
  type: IPAMProvider
```

## Create clusterctl config

```yaml
## -- Controller settings -- ##
PROXMOX_URL: "https://homex10.local.zachary.day:8006"         # The Proxmox VE host
PROXMOX_TOKEN: "capmox@pve!capi"                              # The Proxmox VE TokenID for authentication
PROXMOX_SECRET: ""                                            # The secret associated with the TokenID


## -- Required workload cluster default settings -- ##
PROXMOX_SOURCENODE: "homex10"                                 # The node that hosts the VM template to be used to provision VMs
TEMPLATE_VMID: "900"                                          # The template VM ID used for cloning VMs
ALLOWED_NODES: "[homex10]"                                    # The Proxmox VE nodes used for VM deployments
VM_SSH_KEYS: ""                                               # The ssh authorized keys used to ssh to the machines.

## -- networking configuration-- ##
CONTROL_PLANE_ENDPOINT_IP: "10.69.1.2"                        # The IP that kube-vip is going to use as a control plane endpoint
NODE_IP_RANGES: "[10.69.1.2-10.69.1.15]"                      # The IP ranges for Cluster nodes
GATEWAY: "10.69.0.1"                                          # The gateway for the machines network-config.
IP_PREFIX: "20"                                               # Subnet Mask in CIDR notation for your node IP ranges
DNS_SERVERS: "[10.69.0.1,1.1.1.1,1.1.0.0]"                    # The dns nameservers for the machines network-config.
BRIDGE: "vmbr0"                                               # The network bridge device for Proxmox VE VMs

## -- xl nodes -- ##
BOOT_VOLUME_DEVICE: "scsi0"                                   # The device used for the boot disk.
BOOT_VOLUME_SIZE: "64"                                        # The size of the boot disk in GB.
NUM_SOCKETS: "2"                                              # The number of sockets for the VMs.
NUM_CORES: "4"                                                # The number of cores for the VMs.
MEMORY_MIB: "32768"                                           # The memory size for the VMs.

EXP_CLUSTER_RESOURCE_SET: "true"                              # This enables the ClusterResourceSet feature that we are using to deploy CNI
CLUSTER_TOPOLOGY: "true"        
```

## Initialize Management Cluster

Ensure you set the current kubeconfig context to the management cluster.

```bash
clusterctl init --infrastructure proxmox --ipam in-cluster --core cluster-api:v1.6.1
```

## Create Workload Cluster

```bash
clusterctl generate cluster proxmox-quickstart \
  --config ./clusterctl.yaml \
  --infrastructure proxmox \
  --kubernetes-version v1.30.1 \
  --control-plane-machine-count 1 \
  --worker-machine-count 3 \
  --list-variables
```
