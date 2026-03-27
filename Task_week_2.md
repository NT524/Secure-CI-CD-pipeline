# Task_week_2

## 1. Nhiệm vụ của Khôi (Thành viên A): Tích hợp Pre-commit hooks (Local)

Nhiệm vụ của là thiết lập một "chốt chặn" ngay trên máy tính của developer. Mỗi khi gõ lệnh `git commit`, hệ thống phải tự động chạy kiểm tra trước khi cho phép commit thành công.

- **Công cụ sử dụng:** Framework `pre-commit`, kết hợp với `gitleaks` (để tìm secret bị lộ) và các linters (như ESLint cho JS hoặc Bandit cho Python).
- **Các bước triển khai gợi ý:**
    - Tạo một file `.pre-commit-config.yaml` ở thư mục gốc của repo.
    - Khai báo hook cho `gitleaks` vào file cấu hình này.
    - **Kiểm thử (Test plan):** Cố tình giả lập lỗi bằng cách thêm một đoạn mã hardcode (ví dụ: gán cứng API Key hoặc mật khẩu DB vào file code). Sau đó chạy `git commit` xem `gitleaks` có phát hiện và chặn lại (fail build) không.

## 2. Nhiệm vụ của Bạn Trung (Thành viên B): Tích hợp SAST & SCA trên CI

Bạn sẽ lo phần "chốt chặn" thứ hai trên GitHub. Khi code vượt qua được máy local và đẩy lên GitHub (Push/Pull Request), CI Pipeline sẽ quét sâu hơn vào mã nguồn và các thư viện phụ thuộc.

- **Công cụ sử dụng:** `Semgrep` để quét mã nguồn (SAST) và `Dependabot` hoặc `Snyk` để quét thư viện (Dependency scanning/SCA).
- **Các bước triển khai gợi ý:**
    - Mở file `.github/workflows/ci.yml` của tuần 1 và thêm các job mới.
    - Sử dụng các action có sẵn của GitHub, ví dụ như `returntocorp/semgrep-action@v1` để chạy Semgrep.
    - Bật tính năng Dependabot có sẵn trong mục Settings của repo GitHub để nó tự động tạo Pull Request cảnh báo nếu phát hiện thư viện có lỗ hổng.
    - **Kiểm thử (Test plan):** Cố tình khai báo một thư viện cũ có chứa lỗi bảo mật (CVE) trong file `requirements.txt` hoặc `package.json` để kiểm tra xem hệ thống có cảnh báo vượt ngưỡng (threshold) và chặn việc merge PR hay không.

---

## 💡 Cảnh báo rủi ro (Mentor's Tips)

Khi bắt đầu đưa các công cụ bảo mật vào, rất dễ gặp phải 2 vấn đề đau đầu sau:

1. **Chết chìm trong "False Positives" (Cảnh báo giả):** Lần đầu chạy Semgrep, nó có thể báo hàng tá lỗi khiến pipeline đỏ quạch. Các em cần tìm hiểu và thiết lập quy trình suppression/allowlist để đánh dấu bỏ qua các lỗi không thực sự là rủi ro (có thể quy định thời gian sống - TTL cho các ngoại lệ này). Đừng để dev bị ức chế.
2. **Làm giảm trải nghiệm Developer (Developer friction):** Nếu pre-commit chạy quá lâu hoặc block code một cách vô lý, nó sẽ làm chậm tiến độ làm việc. Hãy cấu hình sao cho nó phản hồi thật nhanh (fast feedback).
