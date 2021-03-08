# Kubespray Bootstrap

This is a set of files to bootstrap Kubespray, which in turn is a tool to bootstrap Kubernetes.

This creates a local installation of python, ansible and terraform in order to bootstrap a Google Compute Platform Kubernetes installation.

## Setup

Quickstart should be:

    git clone https://github.com/kwanlowe/kubespray-bootstrap-test.git
    cd kubespray-bootstrap
    make setup
	source setup.env

Once setup, initialize the Terraform environment and apply. This example is in GCP and creates a free-tier resource.

    cd tf/gcp
    terraform init
    terraform apply

Return to the checkov base directory to run the scan.

    cd ../../
    checkov -d tf/gcp


To integrate bridgecrew visualization, go to bridgecrew.cloud then the API integrations and copy the key. IN PROGRESS

## GCP

Download the credentials then export the variable to point to the JSON file.

    export GOOGLE_APPLICATION_CREDENTIALS=~/.ssh/kubespray-rccl-6c31ddf6cafa.json


