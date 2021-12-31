resource "local_file" "private_key" {
  sensitive_content = tls_private_key.key.private_key_pem
  filename          = format("%s/%s/%s", abspath(path.root), ".ssh", aws_key_pair.key.key_name)
  file_permission   = "0600"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl", {
    ip                = aws_spot_instance_request.this.public_ip,
    ssh_keyfile       = local_file.private_key.filename
  })
  
  filename = "ansible/inventory.yaml"
}
