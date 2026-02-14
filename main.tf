resource "google_storage_bucket" "frontend" {
  name     = "${var.project_id}-frontend"
  location = var.region

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
  force_destroy = true
}

resource "google_storage_bucket_iam_member" "frontend_public_access" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

## BACKEND
resource "google_compute_instance" "backend_vm" {
  name         = "backend-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

metadata_startup_script = <<-EOF
#!/bin/bash

set -e

apt update
apt install -y docker.io google-cloud-sdk

# Esperar que metadata esté lista
sleep 10

# Configurar autenticación Docker con la identidad de la VM
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Crear red interna
docker network create backend-net || true

# Pull imágenes primero
docker pull us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/users-service:${var.image_tag}
docker pull us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/academic-service:${var.image_tag}
docker pull us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/api-gateway:${var.image_tag}

# Ejecutar contenedores
docker run -d --restart unless-stopped \
  --name users-service \
  --network backend-net \
  -e PORT=3001 \
  -e JWT_SECRET=${var.jwt_secret} \
  us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/users-service:${var.image_tag}

docker run -d --restart unless-stopped \
  --name academic-service \
  --network backend-net \
  -e PORT=3002 \
  us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/academic-service:${var.image_tag}

docker run -d --restart unless-stopped \
  --name api-gateway \
  --network backend-net \
  -p 3000:3000 \
  -e PORT=3000 \
  -e JWT_SECRET=${var.jwt_secret} \
  -e USERS_SERVICE_URL=http://users-service:3001 \
  -e ACADEMIC_SERVICE_URL=http://academic-service:3002 \
  us-central1-docker.pkg.dev/${var.project_id}/microservices-repo/api-gateway:${var.image_tag}

EOF      
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

## FIREWALL
resource "google_compute_firewall" "allow_backend" {
  name    = "allow-backend-port"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
}