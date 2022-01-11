##################################################################################
# Grab AD data for OCI VCN
##################################################################################
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

##################################################################################
#  Create OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "services-hub-vcn" {
  cidr_blocks    = [var.services_hub_cidr_block]
  dns_label      = "TransitHub"
  compartment_id = var.compartment_ocid
  display_name   = "Services-Hub"
}

##################################################################################
# Create FW subnet Internal for OCI VCN
##################################################################################
resource "oci_core_subnet" "fw-subnet" {
  cidr_block        = var.fw_subnet_cidr
  display_name      = "FW-Subnet"
  dns_label         = "FWSubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.services-hub-vcn.id
  security_list_ids = [oci_core_vcn.services-hub-vcn.default_security_list_id]
  # route_table_id    = oci_core_vcn.services-hub-vcn.default_route_table_id
  route_table_id    = oci_core_route_table.fw-subnet-route-table.id
  dhcp_options_id   = oci_core_vcn.services-hub-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}

##################################################################################
# Add rule to security list for public subnet for OCI VCN
##################################################################################
resource "oci_core_default_security_list" "services-hub-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.services-hub-vcn.default_security_list_id

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
resource "oci_core_internet_gateway" "services-hub-oci-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.services-hub-vcn.id
    #Optional
    display_name = "Services-Hub-IGW"
}

##################################################################################
# Create Route Table Services-FW OCI cloud VCN
################################################################################## 
resource "oci_core_route_table" "services-fw-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.services-hub-vcn.id
    display_name = "FW-Services-RT"

    // Task #9 Configure ingress routing in Services-Hub VCN to send all inbound 
    // traffic to the firewall instance.
    route_rules {
        #Required
        # network_entity_id = "${lookup(data.oci_core_private_ips.services-hub-vcn-instance-private-ip-datasource.private_ips[0],"id")}"
        network_entity_id = data.oci_core_private_ips.services-hub-vcn-instance-private-ips-datasource.private_ips[0]["id"]
        # network_entity_id = "ocid1.privateip.oc1.iad.abuwcljre5mvlu2rjhtidt6yna7o7fgblsoq66ydjmx6m4tnpttbar6xiywa"
        #Optional
        destination = var.spoke_a_cidr_block
    }

    route_rules {
        # network_entity_id = "${lookup(data.oci_core_private_ips.services-hub-vcn-instance-private-ip-datasource.private_ips[0],"id")}"
        network_entity_id = data.oci_core_private_ips.services-hub-vcn-instance-private-ips-datasource.private_ips[0]["id"]
        #Optional
        destination = var.spoke_b_cidr_block
    } 

    route_rules {
        # network_entity_id = "${lookup(data.oci_core_private_ips.services-hub-vcn-instance-private-ip-datasource.private_ips[0],"id")}"
        network_entity_id = data.oci_core_private_ips.services-hub-vcn-instance-private-ips-datasource.private_ips[0]["id"]
        #Optional
        destination = var.onprem_cidr_block
    }  
  }
##################################################################################
# Create Route Table FW-Subnet OCI cloud VCN
################################################################################## 
resource "oci_core_route_table" "fw-subnet-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.services-hub-vcn.id
    display_name = "FW-Subnet-RT"

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.services-hub-oci-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }

    // Task #10 Configure VCN egress routing in VCN-Fire's subnet named Subnet-H to send all traffic destined to addresses in the VCN CIDRs of Spoke-A, 
    // Spoke-B,and On-Prem to the DRG attachment.
    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.spoke_a_cidr_block
    }

    // Task #10 Configure VCN egress routing in VCN-Fire's subnet named Subnet-H to send all traffic destined to addresses in the VCN CIDRs of Spoke-A, 
    // Spoke-B,and On-Prem to the DRG attachment.
    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.spoke_b_cidr_block
    }

    route_rules {
        #Required
        network_entity_id = oci_core_drg.services-hub-vcn-drg.id
        #Optional
        destination = var.onprem_cidr_block
    }
}