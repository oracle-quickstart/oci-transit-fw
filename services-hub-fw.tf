##################################################################################
# Create FW Instance for OCI VCN
##################################################################################
resource "oci_core_instance" "services-hub-vcn-instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "Services-Hub-FW"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id      = oci_core_subnet.fw-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "services-hub-vcn-fw-subnet-vnic"
    skip_source_dest_check = true
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
  }

  // Ansible integration
  provisioner "remote-exec" {
    inline = ["echo About to run Ansible on FW and waiting!"]

    connection {
      host        = "${oci_core_instance.services-hub-vcn-instance.public_ip}"
      type        = "ssh"
      user        = "${var.user}"
      private_key = file("${var.private_key_path}")
    }
  }

    provisioner "local-exec" {
      command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${oci_core_instance.services-hub-vcn-instance.public_ip},' --private-key ${var.private_key_path} ./ansible/services-hub-fw.yml"
    }
  }  

// Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "services-hub-vcn-instance-vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.services-hub-vcn-instance.id
}

// Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "services-hub-vcn-instance-vnic" {
  vnic_id = data.oci_core_vnic_attachments.services-hub-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "services-hub-vcn-instance-private-ips-datasource" {
  vnic_id    = data.oci_core_vnic.services-hub-vcn-instance-vnic.id
}