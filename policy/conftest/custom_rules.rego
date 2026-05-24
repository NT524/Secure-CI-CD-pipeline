package main
package terraform.S3
import rego.v1

# 1. Luật cấm sử dụng các loại instance quá lớn
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  
  instance_type := resource.change.after.instance_type
  startswith(instance_type, "p")
  
  msg := sprintf("CẢNH BÁO: Tài nguyên %s sử dụng instance %s bị cấm vì lý do chi phí!", [resource.address, instance_type])
}

# 2. Luật bắt buộc gán Tag
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  
  tags := resource.change.after.tags
  not tags.Owner
  
  msg := sprintf("CẢNH BÁO: S3 Bucket %s chưa gắn tag bắt buộc 'Owner'.", [resource.address])
}

# 3. Luật bắt buộc mã hóa đĩa cứng
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  
  not resource.change.after.server_side_encryption_configuration
  
  msg := sprintf("CẢNH BÁO: S3 Bucket %s chưa bật mã hóa dữ liệu!", [resource.address])
}

# 4. S3 không được public
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  resource.change.after.acl == "public-read"
  msg = sprintf("CẢNH BÁO: S3 %s đang ở trạng thái public", [resource.address])
}