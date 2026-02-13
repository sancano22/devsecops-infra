output "frontend_url" {
  value = "http://${google_storage_bucket.frontend.name}.storage.googleapis.com"
}

output "vm_public_ip" {
  value = google_compute_instance.backend_vm.network_interface[0].access_config[0].nat_ip
}
