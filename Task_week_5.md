

Tuần 5 là một điểm nút quan trọng, chuyển từ bảo mật tĩnh sang bảo mật động và kiểm soát policy trước khi ra production.

**Đối với Khôi (Thành viên A - Mảng App & CI/CD):**

* **Nhiệm vụ:** Tích hợp OWASP ZAP vào pipeline để bắn tự động vào URL của Staging.
* **Cách làm:** Em sẽ dùng GitHub Actions để chạy OWASP ZAP ở chế độ automation.
* **Gợi ý kỹ thuật:** Thay vì cài đặt phức tạp, hãy dùng Docker image của ZAP (`owasp/zap2docker-stable`) và chạy kịch bản `zap-baseline.py` trỏ vào URL staging của nhóm.
* **Lưu ý:** Chỉ giới hạn DAST ở các bài test không phá hủy (non-destructive tests) để tránh sập môi trường. Phân tích file JSON output của ZAP để chuyển thành cảnh báo trên GitHub.

**Đối với bạn Trường (Thành viên B - Mảng Hạ tầng IaC & Policy):**

* **Nhiệm vụ:** Cấu hình Policy Gate để chặn các image không có chữ ký.
* **Cách làm:** Nghiên cứu và triển khai OPA Gatekeeper trên cụm Kubernetes (hoặc Minikube).
* **Gợi ý kỹ thuật:** Viết rule bằng ngôn ngữ Rego để thực hiện Admission Webhook. Webhook này sẽ có nhiệm vụ kiểm tra xem container image chuẩn bị được deploy đã được ký bằng công cụ Cosign ở Tuần 4 chưa. Nếu chưa ký hoặc chữ ký không hợp lệ, Gatekeeper phải chặn (deny) quá trình deploy.



