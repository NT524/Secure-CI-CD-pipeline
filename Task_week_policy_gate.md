# Task tuần này: Policy Gate chặn image chưa ký

## Mục tiêu

Triển khai `Admission Webhook` bằng `OPA Gatekeeper` để chặn mọi workload trong namespace `nodegoat-staging` nếu có container image không verify được chữ ký `Cosign`.

## Những gì đã làm trong repo

### 1. Gatekeeper policy

Policy nằm tại:

- [policy/gatekeeper/constraint-template.yaml](/home/trageaeg/Secure-CI-CD-pipeline/policy/gatekeeper/constraint-template.yaml)
- [policy/gatekeeper/constraint.yaml](/home/trageaeg/Secure-CI-CD-pipeline/policy/gatekeeper/constraint.yaml)

`ConstraintTemplate` dùng `Rego` để:

- lấy toàn bộ image từ `Pod`, `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob`
- gọi `external_data(...)` đến provider tên `cosign-gatekeeper-provider`
- `deny` nếu provider báo lỗi, không trả về kết quả, hoặc `verified=false`

`Constraint` hiện áp vào toàn bộ workload trong namespace `nodegoat-staging` và không còn allowlist image nữa.

### 2. Cosign verification provider

Provider runtime nằm tại:

- [policy/cosign-provider/app.py](/home/trageaeg/Secure-CI-CD-pipeline/policy/cosign-provider/app.py)
- [policy/cosign-provider/Dockerfile](/home/trageaeg/Secure-CI-CD-pipeline/policy/cosign-provider/Dockerfile)
- [policy/gatekeeper/provider-deployment.yaml](/home/trageaeg/Secure-CI-CD-pipeline/policy/gatekeeper/provider-deployment.yaml)
- [policy/gatekeeper/provider.yaml](/home/trageaeg/Secure-CI-CD-pipeline/policy/gatekeeper/provider.yaml)

Provider này không dùng sample upstream đã archive nữa. Thay vào đó, nó:

- mount `cosign.pub` từ secret `cosign-public-key`
- gọi `cosign verify --key /keys/cosign.pub <image>`
- mount thêm `ghcr-registry-auth` để verify được image private trên `GHCR`

### 3. Tách MongoDB khỏi namespace bị enforce

Để policy đúng với yêu cầu "mọi image trong namespace staging đều phải có chữ ký", MongoDB đã được tách sang namespace riêng `nodegoat-data`:

- [k8s/mongodb_namespace.yaml](/home/trageaeg/Secure-CI-CD-pipeline/k8s/mongodb_namespace.yaml)
- [k8s/mongodb_deployment.yaml](/home/trageaeg/Secure-CI-CD-pipeline/k8s/mongodb_deployment.yaml)
- [k8s/mongodb_service.yaml](/home/trageaeg/Secure-CI-CD-pipeline/k8s/mongodb_service.yaml)
- [terraform/Namespace.tf](/home/trageaeg/Secure-CI-CD-pipeline/terraform/Namespace.tf)

NodeGoat đã được cập nhật để kết nối MongoDB qua FQDN cross-namespace:

- [k8s/nodegoat_deployment.yaml](/home/trageaeg/Secure-CI-CD-pipeline/k8s/nodegoat_deployment.yaml)

## Luồng hoạt động

1. CI build image ứng dụng và ký bằng `cosign sign`.
2. Cluster cài `Gatekeeper` với `external data`.
3. Khi `kubectl apply` workload vào `nodegoat-staging`, `Gatekeeper` gọi provider.
4. Provider dùng `cosign verify --key cosign.pub` để kiểm tra chữ ký image.
5. Nếu không verify được, request bị `deny`.

## Tích hợp vào GitHub Actions

Workflow đã được cập nhật tại [`.github/workflows/ci.yml`](/home/trageaeg/Secure-CI-CD-pipeline/.github/workflows/ci.yml):

- build image app và ký bằng Cosign
- build local image cho provider
- tạo cluster Kind bằng Terraform
- cài `Gatekeeper`
- bật `--enable-external-data`
- load provider image vào Kind
- sync `COSIGN_PUBLIC_KEY` và `GHCR_PAT` vào cluster
- apply `provider`, `ConstraintTemplate`, `Constraint`
- deploy MongoDB vào `nodegoat-data`
- deploy NodeGoat vào `nodegoat-staging`

Workflow SSH test cũng đã được chỉnh theo namespace mới ở [`.github/workflows/test_ssh.yml`](/home/trageaeg/Secure-CI-CD-pipeline/.github/workflows/test_ssh.yml).

## Cách demo local

Script demo end-to-end:

- [scripts/local_policy_gate_demo.sh](/home/trageaeg/Secure-CI-CD-pipeline/scripts/local_policy_gate_demo.sh)

Ví dụ chạy case fail:

```bash
UNSIGNED_IMAGE=nginx:latest ./scripts/local_policy_gate_demo.sh
```

Script sẽ:

- dựng `kind` cluster
- cài `Gatekeeper`
- build và load provider image
- apply policy
- thử deploy image chưa ký vào `nodegoat-staging`

Kỳ vọng: bị `deny`.

## Kết quả kiểm tra đã làm

### Case fail

Đã test thực tế trên cluster local với image chưa ký.

Ví dụ:

```bash
kubectl run test-unsigned \
  --image=ghcr.io/nt524/secure-ci-cd-pipeline/nodegoat:unsigned-test \
  -n nodegoat-staging
```

Kết quả:

```text
admission webhook "validation.gatekeeper.sh" denied the request
```

### Case control

Đã xác nhận MongoDB không còn nằm trong namespace bị policy enforce, nên không làm sai yêu cầu đề bài.

## Lưu ý quan trọng

- Tag dạng `sha256-...sig` trên GHCR là artifact chữ ký của Cosign, không phải image app để deploy.
- Để demo case `pass`, phải dùng một tag image thật đã ký, ví dụ tag kiểu commit SHA.
- Nếu image trên GHCR là private, provider phải có secret `ghcr-registry-auth`, nếu không `cosign verify` sẽ fail vì không đọc được manifest/signature.

## Điểm có thể trình bày trong báo cáo

- Tại sao `Gatekeeper` cần `external data provider`: Rego không tự verify Cosign trực tiếp với registry.
- Tại sao phải tách `nodegoat-data` khỏi `nodegoat-staging`: để policy đúng nghĩa "mọi image trong namespace bảo vệ đều phải có chữ ký".
- Cơ chế `fail-closed`: provider lỗi hoặc không verify được thì deploy bị chặn.
- Sự khác nhau giữa `cosign sign` ở CI và `cosign verify` ở admission stage.
