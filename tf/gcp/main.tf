provider "google" {
  project = "kubespray-rccl"
  region  = "us-central1"
  zone    = "us-central1-c"
}


variable "client_external_ip" {
  type = string
  description = "This is the external IP address of the client generating the infrastructure."
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags = ["jumpoff"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
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
  target_tags = ["jumpoff"]
  source_ranges = [var.client_external_ip]
}


