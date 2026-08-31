resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.ini.tftpl", {
    node1_ip = module.node1.private_ip
    node1_id = module.node1.id

    node2_ip = module.node2.private_ip
    node2_id = module.node2.id

    node3_ip = module.node3.private_ip
    node3_id = module.node3.id
  })
}