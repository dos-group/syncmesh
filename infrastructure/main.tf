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

resource "google_compute_project_metadata" "my_ssh_key" {
  metadata = {
    ssh-keys = join("\n", [for key in var.ssh_keys : "${key.user}:${key.keymaterial}"])
  }
}

resource "google_compute_subnetwork" "subnet_with_logging" {
  name          = "syncmesh-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id



  log_config {

    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "syncmesh-network"
  auto_create_subnetworks = false

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

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = join("\n", [for key in var.ssh_keys : "${key.user}:${key.keymaterial}"])
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_with_logging.name
    access_config {
    }
  }
  metadata_startup_script = file("${path.module}/setup_scripts/syncmesh-startup.sh")
}

resource "google_compute_instance" "client" {
  name         = "client-instance"
  machine_type = "f1-micro"

  tags = ["demo-vm-instance"]
  metadata = {
    ssh-keys = join("\n", [for key in var.ssh_keys : "${key.user}:${key.keymaterial}"])
  }


  boot_disk {
    initialize_params {
      image = data.google_compute_image.container_optimized_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_with_logging.name
    access_config {
    }
  }
  metadata_startup_script = templatefile("${path.module}/setup_scripts/client-startup.tpl", { instances = google_compute_instance.vm_instance })
}



resource "google_compute_firewall" "ssh-rule" {
  name    = "demo-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags   = ["demo-vm-instance"]
  source_ranges = ["0.0.0.0/0"]
}




# Monitoring 

locals {
  servers = concat(google_compute_instance.vm_instance[*].network_interface.0.network_ip, [google_compute_instance.client.network_interface.0.network_ip])
}

locals {
  server_combinations = setproduct(local.servers, local.servers)
}

resource "google_logging_metric" "logging_metric" {
  for_each = {
    for combination in local.server_combinations :
    sha1("${combination[0]}-${combination[1]}") => combination
  }
  name   = "syncmesh-${each.value[0]}-${each.value[1]}"
  filter = <<EOF
logName:("projects/${var.project}/logs/compute.googleapis.com%2Fvpc_flows")
jsonPayload.connection.src_ip="${each.value[0]}"
jsonPayload.connection.dest_ip="${each.value[1]}"
EOF

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "DISTRIBUTION"
    unit         = "By"
    display_name = "Bytes between ${each.value[0]}-${each.value[1]}"
  }
  value_extractor = "EXTRACT(jsonPayload.bytes_sent)"

  bucket_options {
    linear_buckets {
      num_finite_buckets = 3
      width              = 1
      offset             = 1
    }
  }
}

# resource "google_monitoring_dashboard" "dashboard" {
#   dashboard_json = <<EOF
# {
#   "category": "CUSTOM",
#   "displayName": "DSPJ",
#   "mosaicLayout": {
#     "columns": 12,
#     "tiles": [
#       {
#         "height": 4,
#         "widget": {
#           "title": "logging/user/Traffic_between_1_and_2 [MEAN]",
#           "xyChart": {
#             "chartOptions": {
#               "mode": "COLOR"
#             },
#             "dataSets": [
#               {
#                 "minAlignmentPeriod": "60s",
#                 "plotType": "LINE",
#                 "timeSeriesQuery": {
#                   "apiSource": "DEFAULT_CLOUD",
#                   "timeSeriesFilter": {
#                     "aggregation": {
#                       "alignmentPeriod": "60s",
#                       "crossSeriesReducer": "REDUCE_NONE",
#                       "perSeriesAligner": "ALIGN_SUM"
#                     },
#                     "filter": "metric.type=\"logging.googleapis.com/user/Traffic_between_1_and_2\""
#                   }
#                 }
#               }
#             ],
#             "timeshiftDuration": "0s",
#             "yAxis": {
#               "label": "y1Axis",
#               "scale": "LINEAR"
#             }
#           }
#         },
#         "width": 6,
#         "xPos": 0,
#         "yPos": 0
#       }
#     ]
#   }
# }

# EOF
# }
