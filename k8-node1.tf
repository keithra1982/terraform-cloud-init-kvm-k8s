terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  alias = "kvm1"
  uri   = "qemu+ssh://root@172.21.0.249/system"
}

resource "libvirt_pool" "k8_pool_vm1_kvm1" {
  name = "k8_pool_vm1_kvm1"
  type = "dir"
  path = "/root/k8_pool_vm1_kvm1"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.k8_pool_vm1_kvm1.name
  source = "http://nfs/images/focal-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}


resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.k8_pool_vm1_kvm1.name
}


resource "libvirt_domain" "kvm1-node1-domain-k8" {
  name   = "kvm1-node1-ubuntu-k8"
  memory = "4096"
  vcpu   = 2 

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    bridge = "br0"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
