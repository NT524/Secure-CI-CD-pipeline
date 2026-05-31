package main

import rego.v1

# 1. Chặn Service kiểu LoadBalancer để tránh public thẳng ra Internet ở bước quét tĩnh
deny contains msg if {
  input.kind == "Service"
  input.spec.type == "LoadBalancer"

  msg := sprintf("CẢNH BÁO: Service %s không được để type=LoadBalancer trong quét tĩnh CI.", [input.metadata.name])
}

# 2. Bắt buộc container dùng read-only root filesystem
deny contains msg if {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  security_context := object.get(container, "securityContext", {})
  not object.get(security_context, "readOnlyRootFilesystem", false)

  msg := sprintf("CẢNH BÁO: Container %s phải bật readOnlyRootFilesystem=true.", [container.name])
}

# 3. Bắt buộc container thu hồi toàn bộ Linux capabilities
deny contains msg if {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container_drops_all_capabilities(container)

  msg := sprintf("CẢNH BÁO: Container %s phải drop toàn bộ capabilities.", [container.name])
}

# 4. Bắt buộc chặn privilege escalation
deny contains msg if {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  security_context := object.get(container, "securityContext", {})
  not object.get(security_context, "allowPrivilegeEscalation", true) == false

  msg := sprintf("CẢNH BÁO: Container %s phải đặt allowPrivilegeEscalation=false.", [container.name])
}

container_drops_all_capabilities(container) if {
  security_context := object.get(container, "securityContext", {})
  capabilities := object.get(security_context, "capabilities", {})
  drops := object.get(capabilities, "drop", [])
  "ALL" in drops
}
