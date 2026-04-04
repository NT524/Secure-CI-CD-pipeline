
### 6. Hướng dẫn chi tiết Task Tuần 3
Ở tuần này, mục tiêu của nhóm là tích hợp thành công việc tạo Container, quét lỗ hổng Image và quét mã Hạ tầng (IaC).

**Dành cho Khôi (Phụ trách App & Container):**
1.  **Bước 1: Build Image.** Trong file YAML của GitHub Actions,  thêm step chạy lệnh `docker build -t ghcr.io/<tên-repo>:<commit-sha> .`.
2.  **Bước 2: Tạo SBOM với Syft.**  sẽ dùng lệnh `syft ghcr.io/<tên-repo>:<commit-sha> -o json > sbom.json` để trích xuất danh sách tất cả các thành phần có trong image. SBOM rất cần thiết để tracking.
3.  **Bước 3: Quét Image với Trivy.** Tích hợp Trivy bằng câu lệnh `trivy image --severity HIGH,CRITICAL --exit-code 1 ghcr.io/<tên-repo>:<commit-sha>`. Lưu ý tham số `--exit-code 1` sẽ giúp pipeline tự động **báo đỏ (Fail)** nếu phát hiện lỗ hổng mức High hoặc Critical.

**Dành cho Trung (Phụ trách IaC - Terraform):**
1.  **Bước 1: Tích hợp Checkov.** Trong CI pipeline, khai báo một job mới để chạy Checkov lên thư mục chứa code Terraform.  có thể dùng action có sẵn: `bridgecrewio/checkov-action@v10`.
2.  **Bước 2: Xử lý False Positive.** Nếu Checkov báo lỗi nhưng  xác nhận đó là môi trường test an toàn, hãy dùng cú pháp `--skip-check` (Ví dụ: `checkov -d ./terraform --skip-check CKV_AWS_20`) để pipeline vượt qua thành công.

**Nhiệm vụ chung của tuần 3:** Gom chung các step này vào luồng `build_and_scan` sao cho chúng chạy tuân tự và phối hợp ăn ý trên GitHub Actions. 

***
