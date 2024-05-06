resource "google_compute_network" "vpc_network" {
    name                    = "my-vpc"
    auto_create_subnetworks = false 
}

resource "google_compute_subnetwork" "vpc_subnet" {
    name          = "my-subnet"
    ip_cidr_range = "10.177.225.0/24"
    region        = "asia-northeast1"
    network       = google_compute_network.vpc_network.name
}

resource "google_compute_firewall" "allow_http" {
    name    = "allow-http"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "vm_instance" {
    name         = "my-vm"
    machine_type = "e2-micro"
    zone         = "asia-northeast1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.vpc_subnet.name
 
    }
}