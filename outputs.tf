##################################################################################
# Output for Services-Hub-FW public IPs
##################################################################################
output "Services-Hub-FW_public-ip" {
  value = oci_core_instance.services-hub-vcn-instance.public_ip
}
##################################################################################
# Output for Services-Hub-FW private IPs
##################################################################################
output "Services-Hub-FW_private-ip" {
  value = oci_core_instance.services-hub-vcn-instance.private_ip
}


##################################################################################
# Output for Spoke-A public IPs
##################################################################################
output "Spoke-A_public-ip" {
  value = oci_core_instance.spoke-a-vcn-instance.public_ip
}
##################################################################################
# Output for Spoke-A private IPs
##################################################################################
output "Spoke-A_private-ip" {
  value = oci_core_instance.spoke-a-vcn-instance.private_ip
}


##################################################################################
# Output for Spoke-B public IPs
##################################################################################
output "Spoke-B_public-ip" {
  value = oci_core_instance.spoke-b-vcn-instance.public_ip
}
##################################################################################
# Output for Spoke-B private IPs
##################################################################################
output "Spoke-B_private-ip" {
  value = oci_core_instance.spoke-b-vcn-instance.private_ip
}


##################################################################################
# Output for OnPrem public IPs
##################################################################################
output "OnPrem_public-ip" {
  value = oci_core_instance.onprem-vcn-instance.public_ip
}
##################################################################################
# Output for OnPrem private IPs
##################################################################################
output "OnPrem_private-ip" {
  value = oci_core_instance.onprem-vcn-instance.private_ip
}


##################################################################################
# Output for onprem-vcn-libreswan public IPs
##################################################################################
output "OnPrem-Libreswan_public-ip" {
  value = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
}
##################################################################################
# Output for onprem-vcn-libreswan private IPs
##################################################################################
output "OnPrem-Libreswan_private-ip" {
  value = oci_core_instance.onprem-vcn-libreswan-instance.private_ip
}
##################################################################################
# Output for IPSEC tunnel-a headend IP address VCN
##################################################################################
output "IPSEC-Tunnel-A-IP" {
  value = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].vpn_ip
}
##################################################################################
# Output for IPSEC tunnel-b headend IP address VCN
##################################################################################
output "IPSEC-Tunnel-B-IP" {
  value = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].vpn_ip
}