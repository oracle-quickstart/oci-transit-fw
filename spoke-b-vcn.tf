##################################################################################
#  Create OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "spoke-b-vcn" {
  cidr_blocks    = [var.spoke_b_cidr_block]
  dns_label      = "SpokeB"
  compartment_id = var.compartment_ocid
  display_name   = "Spoke-B"
}

##################################################################################
# Create Spoke subnet for OCI VCN
##################################################################################
resource "oci_core_subnet" "spoke-b-subnet" {
  cidr_block        = var.spoke_b_subnet_cidr
  display_name      = "Spoke-B-Subnet"
  dns_label         = "SpokeBSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.spoke-b-vcn.id
  security_list_ids = [oci_core_vcn.spoke-b-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.spoke-b-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.spoke-b-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

##################################################################################
# Add rule to security list for public subnet for OCI VCN
##################################################################################
resource "oci_core_default_security_list" "spoke-b-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.spoke-b-vcn.default_security_list_id

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
data "oci_core_vcn" "spoke-b-default-route-table-id" {
  vcn_id = oci_core_vcn.spoke-b-vcn.id
}

resource "oci_core_internet_gateway" "spoke-b-oci-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.spoke-b-vcn.id
    #Optional
    display_name = "Spoke-B-IGW"
}

##################################################################################
# Create Route Table routes for Spokes in OCI cloud VCN
##################################################################################

resource "oci_core_default_route_table" "spoke-b-default-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    manage_default_resource_id = data.oci_core_vcn.spoke-b-default-route-table-id.default_route_table_id

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.spoke-b-oci-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }

    // Task #10 Configure VCN egress routing in VCN-Fire's subnet named Subnet-H to send all traffic destined to addresses in the VCN CIDRs of spoke-B, 
    // Spoke-B,and On-Prem to the DRG attachment.
    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.spoke_a_subnet_cidr
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
