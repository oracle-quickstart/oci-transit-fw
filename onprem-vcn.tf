##################################################################################
#  Create OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "onprem-vcn" {
  cidr_blocks    = [var.onprem_cidr_block]
  dns_label      = "OnPrem"
  compartment_id = var.compartment_ocid
  display_name   = "OnPrem"
}

##################################################################################
# Create OnPrem subnet for OCI VCN
##################################################################################
resource "oci_core_subnet" "onprem-subnet" {
  cidr_block        = var.onprem_subnet_cidr
  display_name      = "OnPrem-Subnet"
  dns_label         = "OnPremSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.onprem-vcn.id
  security_list_ids = [oci_core_vcn.onprem-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.onprem-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.onprem-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

##################################################################################
# Add rule to security list for public subnet for OCI VCN
##################################################################################
resource "oci_core_default_security_list" "onprem-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.onprem-vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source = "0.0.0.0/0"
  }
}

##################################################################################
# Create IGW for OCI VCN
##################################################################################

// Grab default route table data for Route rules for OCI VCN
data "oci_core_vcn" "onprem-default-route-table-id" {
  vcn_id = oci_core_vcn.onprem-vcn.id
}

resource "oci_core_internet_gateway" "onprem-oci-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.onprem-vcn.id
    #Optional
    display_name = "OnPrem-IGW"
}

##################################################################################
# Create Route Table routes for Spokes in OCI cloud VCN
##################################################################################

resource "oci_core_default_route_table" "onprem-default-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    manage_default_resource_id = data.oci_core_vcn.onprem-default-route-table-id.default_route_table_id

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.onprem-oci-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }

     route_rules {
        #Required
        network_entity_id = "${lookup(data.oci_core_private_ips.onprem-vcn-libreswan-instance-vnic-private-ip-id.private_ips[0],"id")}"         
        #Optional
        destination = var.spoke_a_cidr_block
    }
     route_rules {
        #Required
        network_entity_id = "${lookup(data.oci_core_private_ips.onprem-vcn-libreswan-instance-vnic-private-ip-id.private_ips[0],"id")}"         
        #Optional
        destination = var.spoke_b_cidr_block
    } 
}
data "oci_core_private_ips" "onprem-vcn-libreswan-instance-vnic-private-ip-id" {
    #Optional
    ip_address = oci_core_instance.onprem-vcn-libreswan-instance.private_ip
    subnet_id = oci_core_subnet.onprem-subnet.id
    } 