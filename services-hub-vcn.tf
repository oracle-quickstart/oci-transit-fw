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

##################################################################################
# Create DRG for OCI cloud VCN
##################################################################################
resource "oci_core_drg" "services-hub-vcn-drg" {
  // Required
  compartment_id = var.compartment_ocid
  // Optional
  display_name = "Services-Hub-DRG"
}

// Task #4 Create a DRG route table named "DRG-To-FW-Spokes" in DRG-Services-HUB
resource "oci_core_drg_route_table" "drg-to-fw-spokes-route-table" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  display_name = "DRG-To-FW-Spokes"
  # import_drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
}

// Task #4 Create a DRG route table named "DRG-To-FW-Spokes" in DRG-Services-HUB
// with a single static rule sending all traffic to the Services-Hub VCN attachment.
resource "oci_core_drg_route_table_route_rule" "spokes-drg-route-table-route-rule" {
  // Required - RT ID FOR VCN - drg 'id' + drg VCN route table 'id' + 
  drg_route_table_id = oci_core_drg_route_table.drg-to-fw-spokes-route-table.id
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.services-hub-drg-attachment.id
}

// Create DRG Route Table for DRG-TO-FW On-Prem
resource "oci_core_drg_route_table" "drg-to-fw-on-prem-route-table" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  display_name = "DRG-To-FW-On-Prem"
  # import_drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-vcn-drg-route-distribution.id
}

// Task #4 Create a DRG route table named "DRG-To-FW-OnPrem" in DRG-Services-HUB
// with a single static rule sending all traffic to the Services-Hub VCN attachment.
resource "oci_core_drg_route_table_route_rule" "onprem-to-spokes-drg-route-table-route-rule" {
  // Required - RT ID FOR VCN - drg 'id' + drg VCN route table 'id' + 
  drg_route_table_id = oci_core_drg_route_table.drg-to-fw-on-prem-route-table.id
  destination                = var.spokes_summary_cidr
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.services-hub-drg-attachment.id
}

// Create DRG Route Table "DRG-From-FW"
resource "oci_core_drg_route_table" "drg-from-fw-route-table" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  display_name = "DRG-From-FW"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
}

// Create DRG attachment spoke-a-drg-attachment for OCI VCN
resource "oci_core_drg_attachment" "spoke-a-drg-attachment" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  network_details {
    id = oci_core_vcn.spoke-a-vcn.id
    type = "VCN"
    # route_table_id = oci_core_route_table.services-hub-vcn-drg.id
  }
  display_name = "Spoke-A-DRG-Attachment"
  // Task #5 Change the DRG route table used by the spoke VCN attachments to "DRG-To-FW-Spokes."
  // Change the DRG route tables used by the spoke VCN attachments (Spoke-A, Spoke-B, and VCN-C) 
  // to use the route table created in the previous task, which sends all incoming traffic to Services-Hub VCN.
  drg_route_table_id = oci_core_drg_route_table.drg-to-fw-spokes-route-table.id
}

// Create DRG spoke-b-drg-attachment for OCI VCN
resource "oci_core_drg_attachment" "spoke-b-drg-attachment" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  network_details {
    id = oci_core_vcn.spoke-b-vcn.id
    type = "VCN"
    # route_table_id = oci_core_route_table.services-hub-vcn-drg.id
  }
  display_name = "Spoke-B-DRG-Attachment"
  // Task #5 Change the DRG route table used by the spoke VCN attachments to "DRG-To-FW-Spokes."
  // Change the DRG route tables used by the spoke VCN attachments (Spoke-A, Spoke-B, and VCN-C) 
  // to use the route table created in the previous task, which sends all incoming traffic to Services-Hub VCN.  
  drg_route_table_id = oci_core_drg_route_table.drg-to-fw-spokes-route-table.id
}

// Create DRG services-hub-drg-attachment for OCI VCN
resource "oci_core_drg_attachment" "services-hub-drg-attachment" {
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  network_details {
    id = oci_core_vcn.services-hub-vcn.id
    type = "VCN"
    // Task #9 Configure ingress routing in VCN-Fire to send all inbound traffic to the firewall instance.
    route_table_id = oci_core_route_table.services-fw-route-table.id
  }
  display_name = "Services-Hub-DRG-Attachment"
  // Task#8 Update the DRG route table of VCN-Fire's attachment to use the "DRG-From-FW" DRG route table.
  drg_route_table_id = oci_core_drg_route_table.drg-from-fw-route-table.id
}

// Add DRG route distribution for OCI VCN
resource "oci_core_drg_route_distribution" "services-hub-drg-route-distribution" {
  // Required
  drg_id = oci_core_drg.services-hub-vcn-drg.id
  distribution_type = "IMPORT"
  // optional
  display_name = "Services-Hub-Route-Distributions"
}

// Task #6 In this task, you create an import route distribution in Services-Hub with 
// statements, each importing routes from the VCN attachments used by Spoke-A and Spoke-B.
resource "oci_core_drg_route_distribution_statement" "spoke-a-services-hub-drg-route-distributio-statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
  action = "ACCEPT"
  match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = DRG_ATTACHMENT_ID
    drg_attachment_id = oci_core_drg_attachment.spoke-a-drg-attachment.id
  }
  priority = 1
}

// Task #6 In this task, you create an import route distribution in Services-Hub with 
// statements, each importing routes from the VCN attachments used by Spoke-A and Spoke-B.
resource "oci_core_drg_route_distribution_statement" "spoke-b-services-hub-drg-route-distributio-statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
  action = "ACCEPT"
  match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = DRG_ATTACHMENT_ID
    drg_attachment_id = oci_core_drg_attachment.spoke-b-drg-attachment.id
  }
  priority = 2
}

// Task #6 In this task, you create an import route distribution in Services-Hub with 
// statements, each importing routes from the VCN attachments used by IPSEC Tunnel-A.
resource "oci_core_drg_route_distribution_statement" "ipsec-tunnel-a-services-hub-drg-route-distributio-statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
  action = "ACCEPT"
  match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = DRG_ATTACHMENT_ID
    drg_attachment_id = oci_core_drg_attachment_management.services-hub-vcn-drg-ipsec-attachment-tunnel-a.id
  }
  priority = 3
}

// Task #6 In this task, you create an import route distribution in Services-Hub with 
// statements, each importing routes from the VCN attachments used by IPSEC Tunnel-B.
resource "oci_core_drg_route_distribution_statement" "ipsec-tunnel-b-services-hub-drg-route-distributio-statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.services-hub-drg-route-distribution.id
  action = "ACCEPT"
  match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = DRG_ATTACHMENT_ID
    drg_attachment_id = oci_core_drg_attachment_management.services-hub-vcn-drg-ipsec-attachment-tunnel-b.id
  }
  priority = 4
}