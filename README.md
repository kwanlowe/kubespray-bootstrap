# Kubespray Bootstrap

This is a set of files to bootstrap Kubespray, which in turn is a tool to bootstrap Kubernetes.

This creates a local installation of python, ansible and terraform in order to bootstrap a 
Google Compute Platform Kubernetes installation. The process first sets up the local workstation,
builds a jumpoff and worker nodes in the cloud, downloads the kubespray repository and does some
initial configuration. Once this process is done, you should be able to kick off the kubespray 
installation itself. Yes, this is a bootstrap to a bootstrap.

There are other ways to do this, such as running a kubespray container, but this repo is intended
to demonstrate the setup.



## Setup

* Preqrequisites

  * Google Cloud Project, with credentials downloaded
  * Linux environment (tested on Linux Mint, CentOS, WSL)


* Quickstart should be:

    git clone https://github.com/kwanlowe/kubespray-bootstrap-test.git
    cd kubespray-bootstrap
    make setup
	source setup.env

* Once you source the setup file, run a couple quick checks to make sure everything is in order:

    which gcloud
	which ansible
	which terraform

  Output should show the local installation versus either the system installation (or 'command not found'.

* Next, enable your GCP credential:

    
    export GOOGLE_APPLICATION_CREDENTIALS=~< PATH to Creds file >

E.g.:


    export GOOGLE_APPLICATION_CREDENTIALS=~~/.ssh/kubespray-project-12345.json

Test your credentials with:

    gcloud projects list

You should see a list of projects associated with that ID. NOTE: This depends on you have configured
the particular IAM permissions associated with the credentials. If you are prompted to authenticate 
further, you may need to run ```gcloud auth login``` to prime the credentials.



* If all looks good, you can now initialize the Terraform playbook:

    make terraform-init-workers

This sets up Terraform by downloading plugins and other housekeeping. 

NOTE: Before building, check out the tf/workers/main.tf file to see what is being built. Unfortunately,
the installation cannot use GCP free tier resources because of memory requirements. At current pricing, 
this will cost about $50/month for the resources. 

* Now, build out the infrastructure with:

    make deploy-gcp-kubespray

  Review the changes this will make and enter 'yes' at the prompt.

* Once the inventory is generated, you can test the installation with:

    gcloud compute instances list

Verify that you see the hosts (1 jumpoff and 3 workers). Then, use gcloud to ssh into the environment.
This step creates a private key that will later be used to setup the environment.

    gcloud compute ssh vm-bastion-001 --command "hostname"

If/when prompted to create the private keyspace, accept the installation by pressing enter a couple times.

* Now it's time to kick off the jumpoff host setup:

    make generate-private-key

This creates an SSh keypair. The private key will be installed in the jumpoff and the public keys in the worker
nodes.  NOTE: There is a safer way to do this with GCP key management tools. Unfortunately, it's beyond the 
scope of this demo, but is fairly trivial to get working. 

* Next, generate a local Ansible inventory file:

    make generate-inventory

This step creates an ```inventory/hosts``` file to be used by the subsequent steps.  Verify this with:

    ansible jumpoff -m ping -i inventory/hosts

NOTE: The ansible.cfg file ignores host key checking. This is to streamline the above process. In production
environments you may want to set this up differently.


* Push the SSH keys to the remotes:

    make setup-jumpoff-privkey
    make setup-workers-pubkey

These steps use Ansible to deploy. 

* Next, prepare the jumpoff host:

    make setup-jumpoff-kubespray

NOTE: It is vitally important to examine the playbook associated with this step as it makes some decisions
that I use personally. Your requirements may be different.

* Once this completes, generate the remote inventory file. 

     make generate-kubespray-inventory-jumpoff

This step queries gcloud for the worker and jumpoff hosts and creates the kubspray inventory file.
It will generate a few lines of output and must be run on the remote jumpoff. 

## Kubespray 

These next steps are done on the jumpoff host. 

* SSH into the remote jumpoff:

    gcloud compute ssh vm-bastion-001

* Enable the local python installation:

    source bin/python_venv/bin/activate


* Run the generate inventory commands.

    cd src/kubespray
    declare -a IPS=(10.128.0.4 10.128.0.5 10.128.0.2 )
    CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

* Run the kubespray playbook:

    ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml

* Wait.

This step does take a considerable time to install, averaging about 20 minutes in my tests.

* Once complete, cd to the ```~/kubespray/inventory/mycluster/artifacts``` directory on the jumpoff.

    cd ~/src/kubespray/inventory/mycluster/artifacts

This contains the admin.conf file (point KUBECONFIG to this file for authentication).

* Test the installation:

    cd ~/src/kubespray/inventory/mycluster/artifacts
    export KUBECONFIG=$(pwd)/admin.conf
    ./kubectl get nodes


* Your cluster should be complete and ready for workloads.
