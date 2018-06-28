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

# Installation Manual

The installation procedure is described in the readme of the setup submodule, 
where also the necessary scripts are located. You can find it here: 
[landscape-setup](https://github.com/gardener/landscape-setup)

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