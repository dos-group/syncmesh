terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file("credentials.json")

  project = "dspj-315716"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_project_metadata" "my_ssh_key" {
  metadata = {
    ssh-keys = join("\n", [for key in var.ssh_keys : "${key.user}:${key.keymaterial}"])
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "syncmesh-network"
  auto_create_subnetworks = "true"
}

data "google_compute_image" "container_optimized_image" {
# Use a container optimized image
# See a list of all images : https://console.cloud.google.com/compute/images
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}


resource "google_compute_instance" "vm_instance" {
  count        = var.instance_count
  name         = "syncmesh-instance-${count.index}"
  machine_type = "f1-micro"

  tags         = ["demo-vm-instance"]
  metadata = {
    ssh-keys = join("\n", [for key in var.ssh_keys : "${key.user}:${key.keymaterial}"])
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
  metadata_startup_script = file("${path.module}/startup.sh")
}


resource "google_compute_firewall" "ssh-rule" {
  name = "demo-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["demo-vm-instance"]
  source_ranges = ["0.0.0.0/0"]
}