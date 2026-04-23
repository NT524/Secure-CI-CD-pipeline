

## Triển khai Tuần 4



**Trường: Cấu hình ký Image và đẩy lên GHCR**
Mục tiêu là đảm bảo nguồn gốc của container image trước khi deploy.
* Cài đặt công cụ Cosign trên máy local để làm quen với lệnh tạo cặp khóa (keypair).
* Tạo GitHub Secrets chứa Private Key của Cosign (tuyệt đối không lưu key ở dạng plaintext trong repo).
* Cập nhật file `.github/workflows/ci.yml`: Thêm bước đăng nhập vào GitHub Container Registry (GHCR), push image, sau đó dùng lệnh `cosign sign --key ${{ secrets.COSIGN_KEY }}` để ký.

**Khôi: Hoàn thiện Terraform để Deploy lên Staging**
Mục tiêu là có một môi trường độc lập để lát nữa chạy DAST.
* Cài đặt Minikube hoặc K3s ở local hoặc chuẩn bị một namespace trống nếu em có cluster trên Cloud.
* Viết file Terraform sử dụng Kubernetes Provider. Viết các resource như `kubernetes_deployment` và `kubernetes_service` để kéo (pull) image từ GHCR (mà Thành viên A vừa push) xuống.
* Chạy thử `terraform apply` trên máy em để đảm bảo pod trạng thái là `Running` và truy cập được web qua localhost/IP.

---




