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

resource "google_compute_network" "vpc_network" {
  name                    = "syncmesh-network"
  auto_create_subnetworks = "true"
}


resource "google_compute_instance" "vm_instance" {
  count        = var.instance_count
  name         = "syncmesh-instance-${count.index}"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
  metadata_startup_script = file("${path.module}/startup.sh")
  #   metadata_startup_script = file("${path.module}/startup.sh")
  #   metadata_startup_script = templatefile("${path.module}/startup.sh")
}


