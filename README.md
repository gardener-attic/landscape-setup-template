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

## Step 1: Clone the Repositories and get dependencies

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

## Steps 3-10 (automated)

Steps 3 to 10 are (partly) automated. This section will guide you through the process using the automation scripts. The guide for the manual installation can be found below.

### Step 3: Docker Container
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
* the current folder will be mounted in that container
* your current working directory will be that mounted folder
* the environment variables will be configured (setup/init.sh is called)

### Setup
For the further installation, go into the `setup` folder: `cd setup`

### Step 4: Create a Kubernetes Cluster via Kubify
This step hasn't been automated yet. You can run the cluster setup from here, however, without changing folders:

```
./deploy_kubify.sh
```

You will have to confirm the cluster creation, see step 4 in the manual installation guide (below) for further details.

Make sure that you wait long enough for the cluster to come up before continuing! This usually takes several minutes. You can check whether all nodes are running with `kubectl get pods --all-namespaces`.

### Step 5-9: Gardener Setup
```
./deploy_gardener.sh
```

This script automates steps 5 to 9 and deploys the gardener and its dependencies on your cluster. 

### Step 10: Apply Valid Certificates
Step 10 has been simplified to the following command:

```
./deploy_certmanager.sh
```

Refer to the manual installation guide below for further information.

## Step 3: Build Docker Container

The setup procedure has quite some dependencies on tools and in particular
to specific versions of them. We therefore recommend to build a Docker
container that comes with all tools with correct versions:

```
cd setup
docker build .
```

Once built run the container and initialize the environment

```
docker run -it -v <local landcape directory>:/landscape <image id>  bash
root@249ed6b5d440:/#
root@249ed6b5d440:~# cd /landscape
root@249ed6b5d440:/landscape# source setup/init.sh
```

## Step 4: Create a Kubernetes Cluster with Kubify

Note: we currently use terraform 0.11.3. There was trouble with later
versions so we do recommend that you stick to this version.

For more in-depth information on Kubify read the documentation provided
by the [Kubify project](https://github.com/gardener/kubify).

```
cd /landscape/setup/components
./deploy.sh kubify
```

The script will run terraform but will ask for consent before it will start
creating the cluster. You may want to check the 
`/landscape/terraform.tfvars` file before continuing. Once you are satisfied
enter `yes`.

```
Plan: 168 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Once completed you will see output similar to the following:

```
Apply complete! Resources: 168 added, 0 changed, 0 destroyed.

Outputs:

[...]
```

This means that all the resources have been created successfully but it will
take a couple of minutes until your cluster is up and running. Check this,
for example by making sure all pods are in status "running":

```
root@c41327633d6d:/landscape# kubectl get pods --all-namespaces
NAMESPACE       NAME                                                                  READY     STATUS    RESTARTS   AGE
kube-system     etcd-operator-75dcfcf4f7-xkm4h                                        1/1       Running   0          6m
kube-system     heapster-c8fb4f746-tvts6                                              2/2       Running   0          2m
kube-system     kube-apiserver-hcdnc                                                  1/1       Running   0          6m
[...]
```

## Step 5: Generate Certificates

These are the self-signed certificates used for the dashboard and
identity ingresses (if you are on the internet you can later get
letsencrypt issued certificates).

```
root@2e8e080d2f34:/landscape# cd setup/components
root@2e8e080d2f34:/landscape/setup/components# ./deploy.sh cert
```

## Step 6: Deploy tiller

Tiller is needed to deploy Helm charts in order to deploy Gardener and other needed components

```
root@2e8e080d2f34:/landscape/setup/components# ./deploy.sh helm-tiller
```

## Step 7: Deploy Gardener

Now we can deploy Gardener. If the previous steps were executed successfully
this should be completed in a couple of seconds.

```
root@2e8e080d2f34:/landscape/setup/components# ./deploy.sh gardener
```

You might see a couple of messages like these:

```
Gardener API server not yet reachable. Waiting...
```

while the script waits for the Gardener to start. Once Gardener is up
when the deployment script finished you can verify the correct setup by
running the following command:

```
root@c41327633d6d:/landscape/setup/components# kubectl get shoots
No resources found. 
```

As we do not have a seed cluster yet we cannot create any shoot clusters.
The Gardener itself is installed in the `garden` namespace:

```
root@c41327633d6d:/landscape/setup/components# kubectl get po -n garden
NAME                                          READY     STATUS    RESTARTS   AGE
gardener-apiserver-56cc665667-nvrjl           1/1       Running   0          6m
gardener-controller-manager-5c9f8db55-hfcts   1/1       Running   0          6m
```

## Step 8: Register Garden Cluster as Seed Cluster

In heterogeneous productive environments one would run Gardener and seed in
separate clusters but for simplicity and resource consumption
reasons we will register the Gardener cluster that we have just created also as the seed
cluster. Make sure that the `seed_config` in the landscape file is correct
and matches the region that you are using. Keep in mind that image ids differ
between regions as well.

```
root@2e8e080d2f34:/landscape/setup/components# ./deploy.sh seed-config
```

That's it! If everything went fine you should now be able to create shoot clusters.
You can start with a sample
[manifest](https://github.com/gardener/gardener/blob/master/example/shoot-aws.yaml)
and create a shoot cluster by standard Kubernetes means:

```
root@2e8e080d2f34:/landscape/setup/components# kubectl apply -f shoot-aws.yaml
```

## Step 9: Install Identity and Dashboard

Creating clusters based on a shoot manifest is quite nice but also a little
complex. While almost all aspects of a shoot cluster can be configured it can
be quite difficult for beginners, so go on and install the dashboard:

```
root@c41327633d6d:/landscape/setup/components# ./deploy.sh identity
[...]
root@c41327633d6d:/landscape/setup/components# ./deploy.sh dashboard
[...]
```

Now you should be able to open the "Gardener" dashboard and start creating
shoot clusters. The URL will be composed as follows:

```
https://dashboard.ingress.<clusters.dns.domainname from landsacpe.yaml>
```

Before opening the dashboard you need to open the `identity.ingress` page
and ignore the untrusted self-signed certificate, otherwise you won't be allowed in.

## Step 10: Apply Valid Certificates

Using the Gardener Dashboard with self-signed certificates is awkward and
some browsers even prevent you from accessing it altogether.

The following command will install the 
[cert-manager](https://github.com/jetstack/cert-manager) and request valid
letsencrypt certificates for both the identity and dashboard ingresses:

```
root@49693b61f393:/landscape/setup/components# ./deploy.sh certmanager
```

After one to two minutes valid certificates should be installed.

In addition, a change is necessary to the API server daemon set as the
JWT tokens can now be verified with a different default certificate. Run
the following command:

```
kubectl -n kube-system edit daemonset kube-apiserver
```

and remove the following line from the API server command line options:

```
- --oidc-ca-file=/etc/kubernetes/secrets/ca.crt
```

# Tearing Down the Landscape

Make sure that you delete all shoot clusters (HOW ??) prior to tearing down the
cluster created by Kubify. `kubectl get shoots` should not return any
shoot clusters:

```
root@c41327633d6d:/landscape/setup/components# kubectl get shoots --all-namespaces
No resources found.
```

Next run terraform in order to delete the cluster:

```
root@c41327633d6d:/landscape/setup/components# cd landscape
root@c41327633d6d:/landscape# k8s/bin/tf destroy
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
project only contains configurations and scripts for AWS. We are looking for
help to extend the installation procedure to other cloud providers.

Gardener has quite a lot of nice features such as update operations and
resilience features that we have not configured here but that really should be turned on.

We haven't configured an identity provider for [dex](https://github.com/coreos/dex).
This should be straightforward to do.