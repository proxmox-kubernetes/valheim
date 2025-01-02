terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}/api2/json"
  pm_api_token_id     = var.proxmox_api_user
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "k8-admin" {
  name        = "valheim"
  desc        = "Valheim Server"
  vmid        = 103
  target_node = "pve"
  count       = 1
  clone       = "debian"
  bootdisk    = "scsi0"
  agent       = 1
  os_type     = "cloud-init"
  cores       = 2
  cpu         = "host"
  memory      = 4096
  vm_state    = "running"
  onboot      = true

  disk {
    slot    = "scsi0"
    size    = "16G"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "192.168.10.121"

  provisioner "local-exec" {
    interpreter = ["/bin/bash" ,"-c"]
    command = <<-EOT
      mkdir -p $HOME/valheim-server/config $HOME/valheim-server/data
      cd $HOME/valheim-server/
      cat > $HOME/valheim-server/valheim.env << EOF
      SERVER_NAME=My Server
      WORLD_NAME=Dedicated
      SERVER_PASS=secret
      SERVER_PUBLIC=true
      EOF
      curl -o $HOME/valheim-server/docker-compose.yaml https://raw.githubusercontent.com/lloesche/valheim-server-docker/main/docker-compose.yaml
      docker compose up -d
    EOT
  }
}

