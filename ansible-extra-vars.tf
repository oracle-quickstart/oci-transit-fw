# Export Terraform variable values to an Ansible var_file
resource "local_file" "tf-ansible-extra-vars" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    # Generated by Terraform mgmt configuration.

    cpe_local_ip: ${oci_core_instance.onprem-vcn-libreswan-instance.private_ip}
    cpe_public_ip: ${oci_core_instance.onprem-vcn-libreswan-instance.public_ip}
    oci_headend1: ${data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].vpn_ip}
    oci_headend2: ${data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].vpn_ip}
    cpe_vcn_cidr: ${var.onprem_cidr_block}
    oci_vcn_cidr: ${var.services_hub_cidr_block}
    shared_secret_psk: ${var.shared_secret_psk}
    DOC
  filename = "./tf-ansible-extra-vars.yml"
}