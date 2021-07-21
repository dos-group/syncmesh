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

  project = var.project
  region  = "us-central1"
  zone    = "us-central1-c"
}

# resource "random_id" "server" {
#   keepers = {
#       scenario = var.scenario
#       nodes_scenario = var.instance_scenario
#   }

#   byte_length = 8
# }

locals {
  name_prefix = "experiment-${var.scenario}-${var.instance_scenario}"
}

resource "tls_private_key" "orchestrator_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  deployment_keys = [{
    user        = "orchestrator"
    keymaterial = tls_private_key.orchestrator_key.public_key_openssh
  }]
  ssh_keys = join("\n", [for key in concat(var.ssh_keys, local.deployment_keys) : "${key.user}:${key.keymaterial}"])
}

# resource "google_compute_project_metadata" "my_ssh_key" {
#   metadata = {
#     ssh-keys = local.ssh_keys
#   }
# }



locals {
  # Zones: https://cloud.google.com/compute/docs/regions-zones
  nodes = local.nodes_selection[var.instance_scenario]
  # This is an array with all location the nodes will be deployed in. 
  # The first element will also host client (and server)
  nodes_selection = {
    "wihtout-latency-3" : [
      {
        region   = "us-central1"
        location = "us-central1-a",
        number   = 1
      },
      {
        region   = "us-central1"
        location = "us-central1-a",
        number   = 1
      },
      {
        region   = "us-central1"
        location = "us-central1-a",
        number   = 1
      },
    ],
    "with-latency-3" : [
      {
        region   = "us-central1"
        location = "us-central1-a",
        number   = 1
      },
      {
        region   = "asia-east1"
        location = "asia-east1-a"
        number   = 2
      },
      {
        region   = "europe-north1"
        location = "europe-north1-b"
        number   = 3
      },
    ],
    "with-latency-6" : [
      {
        region   = "us-central1"
        location = "us-central1-a",
        number   = 1
      },
      {
        region   = "asia-east1"
        location = "asia-east1-a"
        number   = 2
      },
      {
        region   = "europe-north1"
        location = "europe-north1-b"
        number   = 3
      },
      {
        region   = "australia-southeast1"
        location = "australia-southeast1-c",
        number   = 4
      },
      {
        region   = "southamerica-east1"
        location = "southamerica-east1-c"
        number   = 5
      },
      {
        region   = "asia-south2"
        location = "asia-south2-c"
        number   = 6
      },
    ]
  }
}

resource "google_compute_subnetwork" "subnet_with_logging" {
  for_each = {
    for index, vm in local.nodes :
    index => vm
  }
  name          = "${local.name_prefix}-subnetwork-${each.value.number}"
  ip_cidr_range = "10.${each.value.number}.0.0/16"
  region        = each.value.region
  network       = google_compute_network.vpc_network.id



  log_config {

    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "${local.name_prefix}-network"
  auto_create_subnetworks = false

}



data "google_compute_image" "container_optimized_image" {
  # Use a container optimized image
  # See a list of all images : https://console.cloud.google.com/compute/images
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}




resource "google_compute_instance" "nodes" {
  for_each = {
    for index, vm in local.nodes :
    index => vm
  }
  name         = "${local.name_prefix}-node-instance-${each.value.number}"
  machine_type = "f1-micro"

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = local.ssh_keys
  }
  zone = each.value.location


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    network_ip = "10.${each.value.number}.0.1${each.value.number}"
    subnetwork = google_compute_subnetwork.subnet_with_logging[each.value.number - 1].name
    dynamic "access_config" {
      for_each = var.public_access ? ["active"] : []
      content {}
    }
  }
  metadata_startup_script = templatefile("${path.module}/setup_scripts/node-startup-${var.scenario}.tpl", { id = each.value.number, testscript = file("${path.module}/test_scripts/orchestrator-${var.scenario}.sh") })
}

resource "google_compute_instance" "client" {
  name         = "${local.name_prefix}-client-instance"
  machine_type = "f1-micro"

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = local.ssh_keys
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_with_logging[0].name
    network_ip = "10.1.0.2"
    dynamic "access_config" {
      for_each = var.public_access ? ["active"] : []
      content {}
    }
  }
  metadata_startup_script = templatefile("${path.module}/setup_scripts/client-startup.tpl", { instances = google_compute_instance.nodes, testscript = file("${path.module}/test_scripts/client-${var.scenario}.py") })
}

resource "google_compute_instance" "central_server" {
  count        = var.scenario == "baseline" || var.scenario == "advanced-mongo" ? 1 : 0
  name         = "${local.name_prefix}-central-server-instance"
  machine_type = "f1-micro"

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = local.ssh_keys
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_with_logging[0].name
    network_ip = "10.1.0.3"
    dynamic "access_config" {
      for_each = var.public_access ? ["active"] : []
      content {}
    }
  }
  metadata_startup_script = templatefile("${path.module}/setup_scripts/server-startup-${var.scenario}.tpl", { instances = google_compute_instance.nodes })
}


resource "google_compute_instance" "test-orchestrator" {
  name         = "${local.name_prefix}-test-orchestrator"
  machine_type = "f1-micro"

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = local.ssh_keys
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_with_logging[0].name
    network_ip = "10.1.0.255"
    dynamic "access_config" {
      for_each = var.public_access ? ["active"] : []
      content {}
    }
  }
  metadata_startup_script = templatefile("${path.module}/setup_scripts/test-orchestrator.tpl", { nodes = google_compute_instance.nodes, client = google_compute_instance.client, server = google_compute_instance.central_server, private_key = tls_private_key.orchestrator_key.private_key_pem, seperator = var.seperator_request_ip, scenario = var.scenario, testscript = file("${path.module}/test_scripts/orchestrator-${var.scenario}.sh") })
}


resource "google_compute_firewall" "ssh-rule" {
  name    = "${local.name_prefix}-rule-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  dynamic "allow" {
    for_each = var.public_access ? ["8080", "27017"] : []
    content {
      protocol = "tcp"
      ports    = [allow.value]
    }
  }

  target_tags   = ["demo-vm-instance"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "traffic-rule" {
  name    = "${local.name_prefix}-rule-application-traffic"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  target_tags   = ["demo-vm-instance"]
  source_ranges = ["10.0.0.0/8"]
}

## Log Export
resource "google_logging_project_sink" "sink" {
  name        = "${local.name_prefix}-sink"
  project     = var.project
  filter      = <<EOF
resource.type="gce_subnetwork"
${join(" OR ", formatlist("resource.labels.subnetwork_name=\"%s\"", [for o in google_compute_subnetwork.subnet_with_logging : o.name]))}
jsonPayload.connection.dest_port="8080" OR jsonPayload.connection.dest_port="27017" OR jsonPayload.connection.src_port="8080" OR jsonPayload.connection.src_port="27017" OR jsonPayload.connection.dest_port="443" OR jsonPayload.connection.src_port="443"
EOF
  destination = "bigquery.googleapis.com/${google_bigquery_dataset.dataset.id}"
  #   unique_writer_identity = var.unique_writer_identity
  unique_writer_identity = true
}

resource "google_project_iam_binding" "log-writer-bigquery" {
  role = "roles/bigquery.dataEditor"

  members = [
    google_logging_project_sink.sink.writer_identity,
  ]
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = replace("${local.name_prefix}", "-", "_")
  friendly_name               = "syncmesh"
  description                 = "Syncmesh export dataset"
  default_table_expiration_ms = 36000000
  delete_contents_on_destroy  = true

  labels = {
    env = "default"
  }

  access {
    role          = "OWNER"
    user_by_email = "habenicht456@gmail.com"
  }
}

resource "google_storage_bucket" "bucket" {
  name          = "${local.name_prefix}-log-bucket"
  force_destroy = true
}


resource "local_file" "external_addresses" {
  content  = templatefile("${path.module}/ips.tpl", { instances = google_compute_instance.nodes })
  filename = "${path.module}/nodes.txt"
}


# For Advanced Logging:
# https://registry.terraform.io/modules/terraform-google-modules/cloud-operations/google/latest
