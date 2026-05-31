package main
import rego.v1

# 1. Luật cấm mở public endpoint cho EKS trong quét tĩnh Terraform
deny contains msg if {
  is_terraform_input
  walk(input, [path, value])
  path_ends_with(path, "cluster_endpoint_public_access")
  value == true

  msg := "CẢNH BÁO: EKS cluster không được bật public endpoint trong quét tĩnh CI."
}

# 2. Luật cấm dùng instance type quá lớn trong node group
deny contains msg if {
  is_terraform_input
  walk(input, [path, value])
  path_ends_with(path, "instance_types")
  instance_type := value[_]
  startswith(instance_type, "p")

  msg := sprintf("CẢNH BÁO: Terraform đang khai báo instance type %s bị cấm vì lý do chi phí.", [instance_type])
}

# 3. Luật bắt buộc cấu hình default_tags cho AWS provider
deny contains msg if {
  is_terraform_input
  has_provider_block
  not has_default_tags

  msg := "CẢNH BÁO: AWS provider phải có default_tags trong quét tĩnh Terraform."
}

is_terraform_input if {
  object.get(input, "terraform", null) != null
}

is_terraform_input if {
  object.get(input, "provider", null) != null
}

is_terraform_input if {
  object.get(input, "module", null) != null
}

is_terraform_input if {
  object.get(input, "resource", null) != null
}

has_provider_block if {
  walk(input, [path, value])
  path_ends_with(path, "provider")
  is_object(value)
}

has_default_tags if {
  walk(input, [path, value])
  path_ends_with(path, "default_tags")
  is_object(value)
}

path_ends_with(path, key) if {
  count(path) > 0
  path[count(path) - 1] == key
}
