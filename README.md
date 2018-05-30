# Project "Gardener" Landscape Setup

Project "Gardener" can be used to set up Kubernetes landscapes with hundreds
or even thousands of clusters. Landscapes can be distributed across various
hypercloud providers on different continents. While well suited for those 
large setups it can be cumbersome and difficult to get started with Gardener,
if you want to setup a development landscape to evaluate Gardener.

Even with this repository a Gardener installation is non-trivial
(but we are working on it). Before attempting an installation,
you should read the Gardener documentation available in the
[Gardener wiki](https://github.com/gardener/documentation/wiki/Architecture)
in order to understand the basic concepts.

In this simplified setup, we will install a Kubernetes cluster with Kubify,
install the Gardener including the Gardener Dashboard and register this cluster
also as a seed cluster. This is perfectly ok for small environments
but installations spanning several cloud providers and regions need a more complex setup.

## Prerequisites

Before getting started make sure you have the following at hand:

* You need an AWS account with sufficient quota to set up a Kubernetes cluster
with a couple of VMs. The defaults for the account should be sufficient for one
small cluster.
* A Linux machine (virtual machine is fine) or a Mac with basic tools such as a
git client and the Docker runtime installed.

# Gardener Installation

Follow these steps to install Gardener. Do not proceed to the next
step in case of errors.

## Step 1: Clone the Repositories and get Dependencies

Get the `landscape-setup-template` from GitHub and initialize the
submodules:

```
git clone  --recursive https://github.com/gardener/landscape-setup-template.git landscape
cd landscape
```

This repository will contain all passwords and keys for your landscape.
You will be in trouble if you loose them so we recommend that you store
this landscape configuration in a private repository. It might be a good idea to change the
origin so you do not accidentally publish your secrets to the public template repository.

## Step 2: Configure the Landscape

There is a `landscape.yaml` file in the landscape project. This is the only
file that you need to modify - all other configuration files will be
derived from this one. Make sure to follow the instructions in the landscape
file.

## Step 3: Build and Run Docker Container

First, you need to change into the setup folder with `cd setup`

```
./docker_build.sh
```

This script will build the container and name the image `gardener_landscape`. 

Then run the container:

```
./docker_run.sh
```

After this,

* you will be connected to the container via an interactive shell
* the landscape folder will be mounted in that container
* your current working directory will be `setup` folder
* `setup/init.sh` is sourced, meaning
  * the environment variables will be set
  * kubectl will be configured to communicate with your cluster

## Step 4: Create a Kubernetes Cluster via Kubify

You can use this script to run the cluster setup:

```
./deploy_kubify.sh
```

The script will wait some time for the cluster to come up and then partly
validate that the cluster is ready.

If you get errors during the cluster setup, just try to run the script again.

Once completed the following command should show all deployed pods:

```
root@c41327633d6d:/landscape# kubectl get pods --all-namespaces
NAMESPACE       NAME                                                                  READY     STATUS    RESTARTS   AGE
kube-system     etcd-operator-75dcfcf4f7-xkm4h                                        1/1       Running   0          6m
kube-system     heapster-c8fb4f746-tvts6                                              2/2       Running   0          2m
kube-system     kube-apiserver-hcdnc                                                  1/1       Running   0          6m
[...]
```

## Step 5-9: Gardener Setup (Automated)

Steps 5-9 are automated. In case you need more control follow
the instructions below for manually running them.

```
./deploy_gardener.sh
```

After successful completion go to step 10 (optional).

## Step 5-9: Gardener Setup (Manual)

The commands shown below need to be run from within the components 
directory of the setup folder:

```
cd /landscape/setup/components
```

### Step 5: Generate Certificates

These are the self-signed certificates used for the dashboard and
identity ingresses (if you are on the internet you can later get
letsencrypt issued certificates).

```
./deploy.sh cert
```

### Step 6: Deploy tiller

Tiller is needed to deploy Helm charts in order to deploy Gardener and other needed components

```
./deploy.sh helm-tiller
```

### Step 7: Deploy Gardener

Now we can deploy Gardener. If the previous steps were executed successfully
this should be completed in a couple of seconds.

```
./deploy.sh gardener
```

You might see a couple of messages like these:

```
Gardener API server not yet reachable. Waiting...
```

while the script waits for the Gardener to start. Once Gardener is up
when the deployment script finished you can verify the correct setup by
running the following command:

```
kubectl get shoots
No resources found. 
```

As we do not have a seed cluster yet we cannot create any shoot clusters.
The Gardener itself is installed in the `garden` namespace:

```
kubectl get po -n garden
NAME                                          READY     STATUS    RESTARTS   AGE
gardener-apiserver-56cc665667-nvrjl           1/1       Running   0          6m
gardener-controller-manager-5c9f8db55-hfcts   1/1       Running   0          6m
```

### Step 8: Register Garden Cluster as Seed Cluster

In heterogeneous productive environments one would run Gardener and seed in
separate clusters but for simplicity and resource consumption
reasons we will register the Gardener cluster that we have just created also as the seed
cluster. Make sure that the `seed_config` in the landscape file is correct
and matches the region that you are using. Keep in mind that image ids differ
between regions as well.

```
./deploy.sh seed-config
```

That's it! If everything went fine you should now be able to create shoot clusters.
You can start with a sample
[manifest](https://github.com/gardener/gardener/blob/master/example/shoot-aws.yaml)
and create a shoot cluster by standard Kubernetes means:

```
kubectl apply -f shoot-aws.yaml
```

### Step 9: Install Identity and Dashboard

Creating clusters based on a shoot manifest is quite nice but also a little
complex. While almost all aspects of a shoot cluster can be configured it can
be quite difficult for beginners, so go on and install the dashboard:

```
./deploy.sh identity
[...]
./deploy.sh dashboard
[...]
```

Now you should be able to open the "Gardener" dashboard and start creating
shoot clusters. The URL will be composed as follows:

```
https://dashboard.ingress.<clusters.dns.domainname from landsacpe.yaml>
```

Before opening the dashboard you need to open the `identity.ingress` page
and ignore the untrusted self-signed certificate, otherwise you won't be allowed in.


## Step 10: Apply Valid Certificates (optional)

Ensure that you are in the components directory for installing the certmanager:

```
cd /landscape/setup/components
```

Using the Gardener Dashboard with self-signed certificates is awkward and
some browsers even prevent you from accessing it altogether.

The following command will install the 
[cert-manager](https://github.com/jetstack/cert-manager) and request valid
letsencrypt certificates for both the identity and dashboard ingresses:

```
./deploy.sh certmanager
```

After one to two minutes valid certificates should be installed.

# Tearing Down the Landscape

Make sure that you delete all shoot clusters prior to tearing down the
cluster created by Kubify (either by deleting them in the Gardener dashboard 
or by using the kubectl command). The following command should 
not return any shoot clusters:

```
kubectl get shoots --all-namespaces
No resources found.
```

There is a [delete-shoot](https://github.com/gardener/gardener/blob/master/hack/delete-shoot)
script in order to delete shoot clusters.

Next run terraform in order to delete the cluster:

```
cd /landscape
k8s/bin/tf destroy
[...]
Plan: 0 to add, 0 to change, 170 to destroy.

Do you really want to destroy?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

Enter `yes` when you are sure that you want to delete the cluster.

# Current State and Outlook

The installation procedure described here is a mere starting point. We
will continue to improve the installation procedure and we are also
happy to accept contributions that make the installation procedure
simpler, more resilient or improve it in any way that you can think of.

While lowering the entry barrier for getting started with Gardener quite
significantly you will notice that it is far from simple.

Gardener currently supports AWS, Azure, GCP, and OpenStack but this
project only contains configurations and scripts for AWS and Openstack. We are looking for
help to extend the installation procedure to other cloud providers.

Gardener has quite a lot of nice features such as update operations and
resilience features that we have not configured here but that really should be turned on.
