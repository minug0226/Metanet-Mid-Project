terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
  }
  # OpenTofu 1.5 이상
  required_version = ">= 1.5.0"
}

provider "openstack" {
  # clouds.yaml의 cloud 이름
  cloud = "openstack"
  # 예: 내부 TLS 인증서를 무시하려면 추가
  # insecure = true
}

# 1. 보안그룹: inbound, outbound 모든 프로토콜 오픈
resource "openstack_networking_secgroup_v2" "allow_icmp_tcp_udp_sg" {
  name        = "allow-icmp-tcp-udp"
  description = "Allow all inbound/outbound ICMP, TCP, UDP"
}


# 1) ICMP in
resource "openstack_networking_secgroup_rule_v2" "icmp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 2) ICMP out
resource "openstack_networking_secgroup_rule_v2" "icmp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 3) TCP in
resource "openstack_networking_secgroup_rule_v2" "tcp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 4) TCP out
resource "openstack_networking_secgroup_rule_v2" "tcp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 5) UDP in
resource "openstack_networking_secgroup_rule_v2" "udp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 6) UDP out
resource "openstack_networking_secgroup_rule_v2" "udp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# 2. k8s-internal 네트워크/서브넷
resource "openstack_networking_network_v2" "k8s_internal_net" {
  name           = "k8s-internal"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k8s_internal_subnet" {
  name            = "k8s-internal-subnet"
  network_id      = openstack_networking_network_v2.k8s_internal_net.id
  cidr            = "192.168.0.0/16"
  ip_version      = 4
  gateway_ip      = null           # 게이트웨이 비활성 (null)
  enable_dhcp     = false           # 원하는 경우 DHCP 활성/비활성 선택
}

# 3. k8s-external 네트워크/서브넷
resource "openstack_networking_network_v2" "k8s_external_net" {
  name           = "k8s-external"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k8s_external_subnet" {
  name            = "k8s-external-subnet"
  network_id      = openstack_networking_network_v2.k8s_external_net.id
  cidr            = "10.10.10.0/24"
  ip_version      = 4
  gateway_ip      = "10.10.10.254"  # 외부 통신 게이트웨이
  enable_dhcp     = false
  dns_nameservers = ["8.8.8.8"]
}

resource "openstack_compute_keypair_v2" "auto_gen_key" {
  name = "tofu-key"
  // public_key = ...  <-- 생략하면 자동 생성됨
}

# 생성된 private_key를 Terraform Output으로 보여주기 (기본적으로 "민감" 처리하는 것을 권장)
output "generated_private_key" {
  description = "This is the newly generated private key from OpenStack"
  value       = openstack_compute_keypair_v2.auto_gen_key.private_key
  sensitive   = true
}


resource "openstack_networking_port_v2" "infra_port_controller" {
  name       = "infra-port-controller"
  network_id = "6c07f67e-1ea4-4726-bf6b-3a83bebb49ff"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
}

resource "openstack_networking_port_v2" "infra_port_compute1" {
  name       = "infra-port-compute1"
  network_id = "6c07f67e-1ea4-4726-bf6b-3a83bebb49ff"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
}

resource "openstack_networking_port_v2" "infra_port_compute2" {
  name       = "infra-port-compute2"
  network_id = "6c07f67e-1ea4-4726-bf6b-3a83bebb49ff"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
}

resource "openstack_networking_port_v2" "infra_port_storage" {
  name       = "infra-port-storage"
  network_id = "6c07f67e-1ea4-4726-bf6b-3a83bebb49ff"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
}

resource "openstack_networking_port_v2" "infra_port_win_vm" {
  name       = "infra-port-win-vm"
  network_id = "6c07f67e-1ea4-4726-bf6b-3a83bebb49ff"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
}





resource "openstack_networking_port_v2" "k8s_external_port_1" {
  name       = "k8s-external-port-1"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = "10.10.10.10"
  }
}

resource "openstack_networking_port_v2" "k8s_external_port_2" {
  name       = "k8s-external-port-2"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = "10.10.10.20"
  }
}

resource "openstack_networking_port_v2" "k8s_external_port_3" {
  name       = "k8s-external-port-3"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = "10.10.10.30"
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_1" {
  name       = "k8s_internal_port_1"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = "192.168.10.100"
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_2" {
  name       = "k8s_internal_port_2"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = "192.168.10.10"
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_3" {
  name       = "k8s_internal_port_3"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = "192.168.10.20"
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_4" {
  name       = "k8s_internal_port_4"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = "192.168.10.30"
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_5" {
  name       = "k8s_internal_port_5"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  
  security_group_ids = [ openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = "192.168.10.40"
  }
}

########################
# 1) Win VM
########################
resource "openstack_compute_instance_v2" "win_vm" {
  name           = "win-vm"
  flavor_name    = "m1.window"  # 실제 존재하는 Flavor
  image_id       = "b0213f0c-1b56-45bc-811d-8158fb3a8069"  # Windows10 이미지 ID
  key_pair       = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_win_vm.id
  }

  # 원하는 포트 연결 (예: 내부 + 외부)
  network {
    port = openstack_networking_port_v2.k8s_internal_port_1.id
  }
  network {
    port = openstack_networking_port_v2.k8s_external_port_1.id
  }
}

########################
# 2) Controller Node
########################
resource "openstack_compute_instance_v2" "controller_node" {
  name          = "controller-node"
  flavor_name   = "t1.k8s"
  image_id      = "7666e39a-b7c4-4cd1-b10b-2e3cb28fc221"
  key_pair      = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    # 위에서 만든 Port
    port = openstack_networking_port_v2.infra_port_controller.id
  }
  # 내부망 NIC만 연결
  network {
    port = openstack_networking_port_v2.k8s_internal_port_2.id
  }
}

########################
# 3) Compute Node1
########################
resource "openstack_compute_instance_v2" "compute_node1" {
  name          = "compute-node1"
  flavor_name   = "t1.k8s"
  image_id      = "7666e39a-b7c4-4cd1-b10b-2e3cb28fc221"
  key_pair      = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_compute1.id
  }

  # 내부망 NIC
  network {
    port = openstack_networking_port_v2.k8s_internal_port_3.id
  }

  # 외부망 NIC
  network {
    port = openstack_networking_port_v2.k8s_external_port_2.id
  }
}

########################
# 4) Compute Node2
########################
resource "openstack_compute_instance_v2" "compute_node2" {
  name          = "compute-node2"
  flavor_name   = "t1.k8s"
  image_id      = "7666e39a-b7c4-4cd1-b10b-2e3cb28fc221"
  key_pair      = openstack_compute_keypair_v2.auto_gen_key.name


  network {
    port = openstack_networking_port_v2.infra_port_compute2.id
  }

  # 내부망 NIC
  network {
    port = openstack_networking_port_v2.k8s_internal_port_4.id
  }

  # 외부망 NIC
  network {
    port = openstack_networking_port_v2.k8s_external_port_3.id
  }
}

########################
# 5) Storage Node
########################
resource "openstack_compute_instance_v2" "storage_node" {
  name          = "storage-node"
  flavor_name   = "t1.k8s"
  image_id      = "7666e39a-b7c4-4cd1-b10b-2e3cb28fc221"
  key_pair      = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_storage.id
  }

  # 내부망 NIC만 연결
  network {
    port = openstack_networking_port_v2.k8s_internal_port_5.id
  }
}

