
resource "google_compute_network" "vpc_europe_network" {
    name                    = "europe-gaming-private-vpc"
    auto_create_subnetworks = false // set to false if you want to manually create subnetworks
}

# Europe - Prototype gaming information
resource "google_compute_subnetwork" "europe_subnet" {
    name          = "europe-subnet"
    ip_cidr_range = "10.177.225.0/24"
    region        = "europe-west1"
    network       = google_compute_network.vpc_europe_network.id
}

resource "google_compute_network" "vpc_america_network" {
    name                    = "america-gaming-private-vpc"
    auto_create_subnetworks = false // set to false if you want to manually create subnetworks
}

# Americas
resource "google_compute_subnetwork" "americas_subnet1" {
    name          = "americas-subnet1"
    ip_cidr_range = "172.16.0.0/20"
    region        = "us-east1"
    network       = google_compute_network.vpc_america_network.self_link
}

resource "google_compute_subnetwork" "americas_subnet2" {
    name          = "americas-subnet2"
    ip_cidr_range = "172.16.16.0/20"  
    region        = "us-west1"
    network       = google_compute_network.vpc_america_network.self_link
}


resource "google_compute_network" "vpc_asia_network" {
    name                    = "asia-gaming-private-vpc"
    auto_create_subnetworks = false // set to false if you want to manually create subnetworks
}

# Asian 
resource "google_compute_subnetwork" "asia_subnet" {
    name          = "asia-subnet"
    ip_cidr_range = "192.168.0.0/16"  
    region        = "asia-southeast1"
    network       = google_compute_network.vpc_asia_network.self_link
}

 # VPN gateway for HQ
resource "google_compute_vpn_gateway" "hq" {
  name    = "hq-vpn-gateway"
  region  = "europe-west1"
  network = google_compute_network.vpc_europe_network.self_link
  depends_on = [ google_compute_subnetwork.europe_subnet ]
}

resource "google_compute_address" "hq_static_ip" {
  name = "hq-static-ip"
  region = "europe-west1"

}

resource "google_compute_forwarding_rule" "hq_vpn_rule1" {
  name = "hq-vpn-rule1"
  region = "europe-west1"
  ip_protocol = "ESP"
  ip_address = google_compute_address.hq_static_ip.address
  target = google_compute_vpn_gateway.hq.self_link
}

resource "google_compute_forwarding_rule" "hq_vpn_rule2" {
  name = "hq-vpn-rule2"
  region = "europe-west1"
  ip_protocol = "UDP"
  ip_address = google_compute_address.hq_static_ip.address
  target = google_compute_vpn_gateway.hq.self_link
  port_range = "500"

}

resource "google_compute_forwarding_rule" "hq_vpn_rule3" {
  name = "hq-vpn-rule3"
  region = "europe-west1"
  ip_protocol = "UDP"
  ip_address = google_compute_address.hq_static_ip.address
  target = google_compute_vpn_gateway.hq.self_link
  port_range = "4500"

}

resource "google_compute_vpn_tunnel" "hq_tunnel" {
  name = "hq-vpn-tunnel"
  region = "europe-west1"
  target_vpn_gateway = google_compute_vpn_gateway.hq.self_link
  peer_ip = google_compute_address.asia_static_ip.address
  shared_secret = sensitive("secret")
  depends_on = [ google_compute_forwarding_rule.hq_vpn_rule1, google_compute_forwarding_rule.hq_vpn_rule2, google_compute_forwarding_rule.hq_vpn_rule3 ]
  ike_version = 2
  local_traffic_selector = [google_compute_subnetwork.europe_subnet.ip_cidr_range]
  remote_traffic_selector = [google_compute_subnetwork.asia_subnet.ip_cidr_range]
}

resource "google_compute_route" "hq_route" {
  name = "hq-route"
  network = google_compute_network.vpc_europe_network.self_link
  dest_range = google_compute_subnetwork.asia_subnet.ip_cidr_range
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.hq_tunnel.self_link
  priority = 1000
  depends_on = [ google_compute_vpn_tunnel.hq_tunnel ]
  
}
 # VPN gateway for Asia
resource "google_compute_vpn_gateway" "asia" {
  name    = "asia-vpn-gateway"
  region  = "asia-southeast1"
  network = google_compute_network.vpc_asia_network.self_link
  depends_on = [ google_compute_subnetwork.asia_subnet ]
}

resource "google_compute_address" "asia_static_ip" {
  name = "asia-static-ip"
  region = "asia-southeast1"
}

resource "google_compute_forwarding_rule" "asia_vpn_rule1" {
  name = "asia-vpn-rule1"
  region = "asia-southeast1"
  ip_protocol = "ESP"
  ip_address = google_compute_address.asia_static_ip.address
  target = google_compute_vpn_gateway.asia.self_link
}

resource "google_compute_forwarding_rule" "asia_vpn_rule2" {
  name = "asia-vpn-rule2"
  region = "asia-southeast1"
  ip_protocol = "UDP"
  ip_address = google_compute_address.asia_static_ip.address
  target = google_compute_vpn_gateway.asia.self_link
  port_range = "500"
}
resource "google_compute_forwarding_rule" "asia_vpn_rule3" {
  name = "asia-vpn-rule3"
  region = "asia-southeast1"
  ip_protocol = "UDP"
  ip_address = google_compute_address.asia_static_ip.address
  target = google_compute_vpn_gateway.asia.self_link
  port_range = "4500"
  
}

resource "google_compute_vpn_tunnel" "asia_tunnel" {
  name = "asia-vpn-tunnel"
  region = "asia-southeast1"
  target_vpn_gateway = google_compute_vpn_gateway.asia.self_link
  peer_ip = google_compute_address.hq_static_ip.address
  shared_secret = sensitive("secret")
  depends_on = [ google_compute_forwarding_rule.asia_vpn_rule1, google_compute_forwarding_rule.asia_vpn_rule2, google_compute_forwarding_rule.asia_vpn_rule3 ]
  ike_version = 2
  local_traffic_selector = [google_compute_subnetwork.asia_subnet.ip_cidr_range]
  remote_traffic_selector = [google_compute_subnetwork.europe_subnet.ip_cidr_range]
}

resource "google_compute_route" "asia_route" {
  name = "asia-route"
  network = google_compute_network.vpc_asia_network.self_link
  dest_range = google_compute_subnetwork.europe_subnet.ip_cidr_range
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.asia_tunnel.self_link
  priority = 1000
  depends_on = [ google_compute_vpn_tunnel.asia_tunnel ]
  
} 


# Peering connection between Americas and HQ
resource "google_compute_network_peering" "americas_to_hq" {
  name      = "americas-to-hq"
  network   = google_compute_network.vpc_america_network.self_link
  peer_network = google_compute_network.vpc_europe_network.self_link
}

resource "google_compute_network_peering" "hq_to_americas" {
  name      = "hq-to-americas"
  network   = google_compute_network.vpc_europe_network.self_link
  peer_network = google_compute_network.vpc_america_network.self_link
  
}
# Peering internal rules
resource "google_compute_firewall" "traffic_rule1" {
  name = "traffic-rule1"
  network = google_compute_network.vpc_europe_network.self_link
  allow {
    protocol = "all"
  }
  source_ranges = ["172.16.0.0/20"]
  depends_on = [ google_compute_network_peering.americas_to_hq, google_compute_network_peering.hq_to_americas ]

}

resource "google_compute_firewall" "traffic_rule2" {
  name = "traffic-rule2"
  network = google_compute_network.vpc_europe_network.self_link
  allow {
    protocol = "all"
  }
  source_ranges = ["172.16.16.0/20"]
  depends_on = [ google_compute_network_peering.americas_to_hq, google_compute_network_peering.hq_to_americas ]

}

resource "google_compute_firewall" "traffic_rule3" {
  name = "traffic-rule3"
  network = google_compute_network.vpc_europe_network.self_link
  allow {
    protocol = "all"
  }
  source_ranges = ["192.168.0.0/16"]
  

}

resource google_compute_firewall "rdp1" {
  name = "rdp1"
  network = google_compute_network.vpc_america_network.id
  allow {
    protocol = "tcp"
    ports = ["3389"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource google_compute_firewall "rdp_asia" {
  name = "rdp-asia"
  network = google_compute_network.vpc_asia_network.id
  allow {
    protocol = "tcp"
    ports = ["3389"]
  }
  source_ranges = ["0.0.0.0/0"]
}

