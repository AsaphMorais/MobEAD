terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Security Group
resource "aws_security_group" "windows_sg" {
  name        = "windows-server-sg"
  description = "Allow RDP, WinRM and HTTP"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Windows Server 2019 - AMI Free Tier us-east-1
resource "aws_instance" "windows_server" {
  ami                    = "ami-075309a66c5dedf22"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.windows_sg.id]


  user_data = <<-USERDATA
    <powershell>
    # Configurar WinRM para Ansible
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    # Abrir firewall para WinRM
    netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
    netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow

    # Definir senha do usuário administrador
    $admin = [adsi]"WinNT://./Administrator,user"
    $admin.SetPassword("Unyleya@2025!")
    $admin.SetInfo()

    # Habilitar usuário administrador
    net user Administrator /active:yes
    </powershell>
  USERDATA

  tags = {
    Name = "windows-server-unyleya"
  }
}

output "public_ip" {
  value = aws_instance.windows_server.public_ip
}

output "instance_id" {
  value = aws_instance.windows_server.id
}
