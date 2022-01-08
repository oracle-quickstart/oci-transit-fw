##################################################################################
#  Create OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "spoke-a-vcn" {
  cidr_blocks    = [var.spoke_a_cidr_block]
  dns_label      = "SpokeA"
  compartment_id = var.compartment_ocid
  display_name   = "Spoke-A"
}

##################################################################################
# Create Spoke subnet for OCI VCN
##################################################################################
resource "oci_core_subnet" "spoke-a-subnet" {
  cidr_block        = var.spoke_a_subnet_cidr
  display_name      = "Spoke-A-Subnet"
  dns_label         = "SpokeASubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.spoke-a-vcn.id
  security_list_ids = [oci_core_vcn.spoke-a-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.spoke-a-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.spoke-a-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

##################################################################################
# Add rule to security list for public subnet for OCI VCN
##################################################################################
resource "oci_core_default_security_list" "spoke-a-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.spoke-a-vcn.default_security_list_id

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
data "oci_core_vcn" "spoke-a-default-route-table-id" {
  vcn_id = oci_core_vcn.spoke-a-vcn.id
}

resource "oci_core_internet_gateway" "spoke-a-oci-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.spoke-a-vcn.id
    #Optional
    display_name = "Spoke-A-IGW"
}

##################################################################################
# Create Route Table routes for Spokes in OCI cloud VCN
##################################################################################

resource "oci_core_default_route_table" "spoke-a-default-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    manage_default_resource_id = data.oci_core_vcn.spoke-a-default-route-table-id.default_route_table_id

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.spoke-a-oci-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }

    // Task #10 Configure VCN egress routing in VCN-Fire's subnet named Subnet-H to send all traffic destined to addresses in the VCN CIDRs of Spoke-A, 
    // Spoke-B,and On-Prem to the DRG attachment.
    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.spoke_b_subnet_cidr
    }

    // Task #10 Configure VCN egress routing in VCN-Fire's subnet named Subnet-H to send all traffic destined to addresses in the VCN CIDRs of spoke-B, 
    // Spoke-B,and On-Prem to the DRG attachment.
    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.onprem_cidr_block
    }      
 }
