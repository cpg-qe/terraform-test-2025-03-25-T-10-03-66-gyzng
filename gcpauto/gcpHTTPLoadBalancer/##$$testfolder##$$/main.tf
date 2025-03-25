# Provider configuration
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials
}

# Create a random ID for dynamic resource naming
resource "random_id" "random_suffix" {
  byte_length = 4
}

# Create an HTTP firewall rule to allow traffic on port 80
resource "google_compute_firewall" "default" {
  name    = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-firewall-rule"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.138.0.0/24"]
}

# Create a VPC network
resource "google_compute_network" "default" {
  name                    = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-network"
  auto_create_subnetworks = true
}

# Create a global IP address for the load balancer
resource "google_compute_global_address" "default" {
  name = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-global-ip"
}

# Create the instance group (backend)
resource "google_compute_instance_group" "default" {
  name        = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-instance-group"
  description = "Managed instance group for the backend"
  zone        = var.zone
  instances   = [google_compute_instance.default.self_link]
}

# Create an instance that serves as a backend for the load balancer
resource "google_compute_instance" "default" {
  name         = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-backend-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20220131"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = google_compute_network.default.name

    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    service apache2 start
    echo "<h1>Hello from GCP Load Balancer Backend</h1>" > /var/www/html/index.html
  EOF
}

# Create a backend service for the instance group
resource "google_compute_backend_service" "default" {
  name        = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  health_checks = [google_compute_health_check.default.self_link]

  backend {
    group = google_compute_instance_group.default.self_link
  }

  connection_draining_timeout_sec = 300
}

# Create a health check for the backend service
resource "google_compute_health_check" "default" {
  name               = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-http-health-check"
  timeout_sec        = 5   # Set this to be less than check_interval_sec
  check_interval_sec = 10  # This can be greater than or equal to timeout_sec
  healthy_threshold  = 2
  unhealthy_threshold = 10

  http_health_check {
    port = 80
  }
}

# URL map for routing requests
resource "google_compute_url_map" "default" {
  name            = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-url-map"
  default_service = google_compute_backend_service.default.self_link
}

# Create a target HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name   = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# Forwarding rule to map the load balancer to the IP address
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.resource_name_prefix}-${random_id.random_suffix.hex}-http-forwarding-rule"
  ip_address = google_compute_global_address.default.address
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}