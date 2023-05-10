packer {
  required_version = ">= 1.7.0"
  required_plugins {
    parallels = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/parallels"
    }
    vagrant = {
      version = ">= 1.0.2"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "user_password" {
  type    = string
  default = "ubuntu"
}

variable "user_password_hash" {
  type    = string
  default = "$6$nSAgaq1pQ5Nj4vLt$XMLQmBDftmbkR.Jn96zvxn0ecZIzow85CDls6CGi/tgRdfyuYg6NsFK7kkMJPctzpLelteyd60hM1d6XJ2cLs/"
}

variable "user_username" {
  type    = string
  default = "ubuntu"
}

variable "hostname" {
  type    = string
  default = "ubuntu"
}

variable "install_desktop" {
  type    = bool
  default = false
}

variable "install_vscode" {
  type    = bool
  default = false
}

variable "install_vscode_server" {
  type    = bool
  default = false
}

source "parallels-iso" "ubuntu2304" {
  guest_os_type          = "ubuntu"
  parallels_tools_flavor = "lin-arm"
  parallels_tools_mode   = "upload"
  prlctl = [
    ["set", "{{ .Name }}", "--efi-boot", "off"]
  ]
  prlctl_version_file = ".prlctl_version"
  boot_command = [
    "<wait>e<wait><down><down><down><end><wait> autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/<f10><wait>"
  ]
  boot_wait      = "10s"
  cpus           = 2
  communicator   = "ssh"
  disk_size      = "65536"
  floppy_files   = null
  iso_checksum   = "file:https://cdimage.ubuntu.com/releases/23.04/release/SHA256SUMS"
  http_directory = "${path.root}/http"
  iso_urls = [
    "https://cdimage.ubuntu.com/releases/23.04/release/ubuntu-23.04-live-server-arm64.iso"
  ]
  memory           = 2048
  output_directory = "ubuntu-parallels"
  shutdown_command = "echo 'ubuntu'|sudo -S shutdown -P now"
  shutdown_timeout = "15m"
  ssh_password     = "ubuntu"
  ssh_port         = 22
  ssh_timeout      = "60m"
  ssh_username     = "ubuntu"
  ssh_wait_timeout = "10000s"
  vm_name          = "ubuntu_23.04"
}

build {
  hcp_packer_registry {
    bucket_name = "learn-packer-ubuntu"
    description = <<EOT
Some nice description about the image being published to HCP Packer Registry.
    EOT
    bucket_labels = {
      "owner"          = "platform-team"
      "os"             = "Ubuntu",
      "ubuntu-version" = "Focal 20.04",
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }
  
  sources = [
    "source.parallels-iso.ubuntu2304"
  ]

  provisioner "shell" {
    environment_vars = [
      "HOME_DIR=/home/ubuntu"
    ]
    scripts = [
      "${path.root}/scripts/update.sh",
      "${path.root}/scripts/sshd.sh",
      "${path.root}/scripts/networking.sh",
      "${path.root}/scripts/sudoers.sh",
      // "${path.root}/scripts/vagrant.sh",
      "${path.root}/scripts/systemd.sh",
      "${path.root}/scripts/parallels.sh",
      "${path.root}/scripts/parallels_folders.sh",
      "${path.root}/scripts/minimize.sh",
    ]

    execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
  }


  provisioner "file" {
    destination = "/parallels-tools/scripts/"
    source      = "${path.root}/scripts/"
    direction   = "upload"
  }

  provisioner "file" {
    destination = "/parallels-tools/files/"
    source      = "${path.root}/files/"
    direction   = "upload"
  }


  // provisioner "shell" {
  //   environment_vars = [
  //       "HOME_DIR=/home/ubuntu"
  //     ]
  //   scripts = [
  //     "${path.root}/scripts/addons/desktop.sh",
  //   ]

  //   execute_command   = "echo 'ubunut' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
  //   expect_disconnect = true
  //   except = var.install_desktop ? [] : ["sources.parallels-iso.ubuntu2304"]
  // }


  // provisioner "shell" {
  //   environment_vars = [
  //       "HOME_DIR=/home/ubuntu"
  //     ]
  //   scripts = [
  //     "${path.root}/scripts/addons/visual_studio_code.sh",
  //   ]

  //   execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
  //   expect_disconnect = true
  //   except = var.install_vscode || var.install_vscode_server ? [] : ["sources.parallels-iso.ubuntu2304"]
  // }

  //   provisioner "shell" {
  //   environment_vars = [
  //       "HOME_DIR=/home/ubuntu"
  //     ]
  //   scripts = [
  //     "${path.root}/scripts/addons/visual_studio_code.sh",
  //   ]

  //   execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
  //   expect_disconnect = true
  //   except = var.install_vscode_server ? [] : ["sources.parallels-iso.ubuntu2304"]
  // }

  // post-processor "vagrant" {
  //   compression_level    = 9
  //   keep_input_artifact  = false
  //   output               = "./builds/ubuntu.{{ .Provider }}.box"
  //   vagrantfile_template = null
  // }
}
