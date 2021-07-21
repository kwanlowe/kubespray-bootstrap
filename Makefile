VENV=python_venv
ROLES_PATH=roles
TF_BINARY_URL=https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip
GCP_BINARY_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-330.0.0-linux-x86_64.tar.gz
SCRATCH=tmp
BINPATH=bin
TFDIR=tf/gcp
PRIVKEY=/home/kwan/.ssh/google_compute_engine


help:
	@grep '^[a-z].*:$$' Makefile|tr -d ':'

install-google-cloud-sdk:
	mkdir -p $(SCRATCH) $(BINPATH)
	wget -P tmp/ $(GCP_BINARY_URL)
	@$(eval GCP_BASENAME=$(shell sh -c "basename $(GCP_BINARY_URL)"))
	tar xf $(SCRATCH)/$(GCP_BASENAME) -C $(SCRATCH)/
	mv $(SCRATCH)/google-cloud-sdk $(BINPATH)
	
install-checkov:
	virtualenv -p $$(which python3) $(VENV)
	$(VENV)/bin/pip install -r requirements.txt
	mkdir -p $(ROLES_PATH)

install-ansible:
	virtualenv -p $$(which python3) $(VENV)
	$(VENV)/bin/pip install -r requirements.txt
	mkdir -p $(ROLES_PATH)

install-terraform:
	mkdir -p $(SCRATCH) $(BINPATH)
	wget -P tmp/ $(TF_BINARY_URL)
	@$(eval TF_BASENAME=$(shell sh -c "basename $(TF_BINARY_URL)"))
	echo $(TF_BASENAME)
	unzip -p $(SCRATCH)/$(TF_BASENAME) terraform >$(BINPATH)/terraform
	chmod +x bin/terraform
	pwd

generate-inventory:
	mkdir -p inventory
	@gcloud compute instances list|awk 'BEGIN{print"[workers]\n"} NR>1 && /worker/{printf "%s ansible_ssh_private_key_file=$(PRIVKEY)\n", $$5}' >inventory/hosts
	@gcloud compute instances list|awk 'BEGIN{print"[jumpoff]\n"} NR>1 && /bastion/{printf "%s ansible_ssh_private_key_file=$(PRIVKEY)\n", $$5}' >>inventory/hosts

setup: install-google-cloud-sdk 	install-ansible 	install-terraform
	@echo Enable the python virtual environment with:
	@echo "    source $(VENV)/bin/activate"
	@echo Add the binary directory to your path with:
	@echo "    export PATH=$$(pwd)/bin:\$$PATH"

run-test:
	checkov -d $(TFDIR)

terraform-init-workers:
	cd tf/workers && terraform init

deploy-gcp-single-node:
	@ $(eval CLIENT_EXTERNAL_IP=$(shell sh -c "curl ifconfig.me 2>/dev/null"))
	@echo $(CLIENT_EXTERNAL_IP)/32
	cd tf/gcp && terraform apply -var="client_external_ip=$(CLIENT_EXTERNAL_IP)/32"

destroy-gcp-single-node:
	cd tf/gcp && terraform destroy

deploy-gcp-kubespray:
	@ $(eval CLIENT_EXTERNAL_IP=$(shell sh -c "curl ifconfig.me 2>/dev/null"))
	@echo $(CLIENT_EXTERNAL_IP)/32
	cd tf/workers && terraform apply -var="client_external_ip=$(CLIENT_EXTERNAL_IP)/32"

generate-private-key:
	mkdir -p playbooks/keys
	test ! -f playbooks/keys/jumpoff && ssh-keygen -b 4096 -t rsa -f playbooks/keys/jumpoff 

setup-workers-pubkey:
	@ $(eval GCLOUD_REMOTE_USER=$(shell sh -c 'gcloud compute ssh vm-bastion-001 --command "whoami"' )) 
	ansible-playbook playbooks/setup-worker-pubkey.yml  -i inventory/hosts -e "gcloud_remote_user=$(GCLOUD_REMOTE_USER)"

setup-jumpoff-privkey:
	@ $(eval GCLOUD_REMOTE_USER=$(shell sh -c 'gcloud compute ssh vm-bastion-001 --command "whoami"' )) 
	ansible-playbook playbooks/setup-host-privkey.yml  -i inventory/hosts -e "gcloud_remote_user=$(GCLOUD_REMOTE_USER)" 

setup-jumpoff-kubespray:
	@echo Installing ansible and other required tools. This will take about 10 minutes.
	ansible-playbook playbooks/setup-kubespray.yml -i inventory/hosts 
	ansible-playbook playbooks/download-kubectl.yml -i inventory/hosts 
	@echo
	@echo The jumpoff host should be ready. Run the following commands:
	@echo "    gcloud compute ssh vm-bastion-001"
	@echo "If prompted, follow the gcloud authentication prompts."
	@echo "Once logged into the remote:"
	@echo "    source ~/bin/python_vebv/bin/activate"

generate-kubespray-inventory-jumpoff:
	@echo "Run the following commands in the remote (jumpoff) shell:"
	@echo -n "    "
	@echo cd src/kubespray
	@echo -n "    "
	@gcloud compute instances list|awk 'BEGIN {printf "declare -a IPS=("} NR>1 && /worker/{printf "%s ", $$4} END{print ")\n"}'
	@echo -n "    "
	@echo 'CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py $${IPS[@]}'

generate-kubespray-inventory-local:
	@echo Run the following commands in shell:
	@echo -n "    "
	@echo cd src/kubespray
	@echo -n "    "
	@gcloud compute instances list|awk 'BEGIN {printf "declare -a IPS=("} NR>1{printf "%s ", $$5} END{print ")\n"}'
	@echo -n "    "
	@echo 'CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py $${IPS[@]}'

	
