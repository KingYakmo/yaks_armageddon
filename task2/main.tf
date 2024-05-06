terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.27.0"
    }
  }
}

provider "google" {
  # Configuration options
  project = "bigmos-project-2024-422504"
  region = "asia-northeast1"
  zone = "asia-northeast1-a"
  credentials = "bigmos-project-2024-422504-79eb77330b9c.json"

}