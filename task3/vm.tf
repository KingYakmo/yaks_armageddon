# Create a VM instance for HQ
resource "google_compute_instance" "web_server" {
  machine_type = "e2-medium"
    metadata = {
    startup-script = "#!/bin/bash\n\n# Update package list and install Apache\napt update\napt install -y apache2\n\n# Start Apache service\nsystemctl start apache2\n\n# Enable Apache service to start on boot\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Welcome to your custom website.</h2>\n<h3>Created with a direct input startup script!</h3>\n<p><b>Instance Name:</b> $(hostname -f)</p>\n<p><b>Instance Private IP Address: </b> $local_ipv4</p>\n<p><b>Zone: </b> $zone</p>\n<p><b>Project ID:</b> $project_id</p>\n<p><b>Network Tags:</b> $network_tags</p>\n</body></html>\nEOF\n"
  } 
  
  name = "eu-web-server"
  zone = "europe-west1-b"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  
  network_interface {
    access_config {
      network_tier = "STANDARD"
    }
    subnetwork = google_compute_subnetwork.europe_subnet.self_link
    network = google_compute_network.vpc_europe_network.self_link
  }
   
}

output "web_url" {
  value = "http://${google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip}"
}