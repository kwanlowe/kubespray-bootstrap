provider "google" {
  project = "kubespray-rccl"
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_client_openid_userinfo" "me" {
    }

variable "client_external_ip" {
  type = string
  description = "This is the external IP address of the client generating the infrastructure."
}


resource "google_os_login_ssh_public_key" "cache" {
    user =  data.google_client_openid_userinfo.me.email
    key = file("/path/to/you/pub/key")
}

resource "google_compute_instance" "vm_instance" {
  allow_stopping_for_update = true
  count = "3"
  name         = "vm-worker-${count.index + 1}"
  machine_type = "n2-standard-2"
  tags = ["kubespray-vm"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_instance" "jumpoff" {
  name         = "vm-bastion-001"
  machine_type = "f1-micro"
  tags = ["kubespray-vm","bastion"]

  boot_disk {
    initialize_params {
      # image = "debian-cloud/debian-9"
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}


resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "fw-allow-ssh" {
  name = "fw-allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["kubespray-vm"]
  source_ranges = [var.client_external_ip]
}

resource "google_compute_firewall" "fw-allow-kubeports" {
  name = "fw-allow-kubeports"
  network = google_compute_network.vpc_network.name
  allow { protocol = "icmp" }
  allow {
    protocol = "tcp"
    ports = ["22", "80", "443", "6443","2379", "2380", "10250"]
  }
  target_tags = ["kubespray-vm"]
  source_ranges = ["10.128.0.0/24"]
}
