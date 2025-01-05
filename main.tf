terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.pve_host}:8006/api2/json"
  pm_api_token_id     = var.pve_user
  pm_api_token_secret = var.pve_password
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "valheim" {
  name = "valheim"
  desc = "Valheim Server"

  count            = 1
  vmid             = 103
  clone            = "debian"
  full_clone       = true
  cores            = 2
  memory           = 4096
  target_node      = "pve"
  agent            = 1
  boot             = "order=scsi0"
  scsihw           = "virtio-scsi-single"
  vm_state         = "running"
  automatic_reboot = true

  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "16G"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 1
    bridge = "vmbr0"
    model  = "virtio"
  }

  os_type   = "cloud-init"
  cicustom  = "user=local:snippets/debian.yml"
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"
  agent_timeout = 120

  connection {
    type        = "ssh"
    user        = "debian"
    private_key = file("~/.ssh/id_rsa")
    host        = self.ssh_host
    port        = self.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "ip a",
      "sudo hostnamectl set-hostname valheim",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p $HOME/valheim-server/config $HOME/valheim-server/data",
      "cd $HOME/valheim-server/",
      "cat > $HOME/valheim-server/valheim.env << EOF",
      "SERVER_NAME=Klaus",
      "WORLD_NAME=Klaus",
      "SERVER_PASS=secret",
      "SERVER_PUBLIC=true",
      "curl -o $HOME/valheim-server/docker-compose.yaml https://raw.githubusercontent.com/lloesche/valheim-server-docker/main/docker-compose.yaml",
      "docker compose up -d",
    ]
  }
}

