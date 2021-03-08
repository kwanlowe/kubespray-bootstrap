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


