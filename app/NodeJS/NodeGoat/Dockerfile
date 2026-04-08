# ==========================================
# STAGE 0: BUILD (Cài đặt dependencies)
# ==========================================
FROM node:18-alpine AS builder

# 1. Đặt thư mục làm việc chuẩn
WORKDIR /usr/src/app

# 2. Copy file quản lý thư viện vào trước để tận dụng Docker cache
COPY package*.json ./

# 3. Cài đặt các thư viện (Lúc này thư mục node_modules sẽ được tạo ra)
RUN npm install

# ==========================================
# STAGE 1: PRODUCTION (Chạy ứng dụng)
# ==========================================
FROM node:18-alpine

# Sửa lại cú pháp ENV có dấu "=" theo cảnh báo của Docker
ENV USER=node
ENV WORKDIR=/home/node/app

WORKDIR $WORKDIR

# 4. Copy node_modules từ stage 'builder' sang (sửa lại đường dẫn cho chuẩn)
COPY --from=builder /usr/src/app/node_modules ./node_modules

# 5. Copy toàn bộ mã nguồn còn lại vào
COPY --chown=node:node . .

# 6. Set quyền cho user non-root (Best practice trong DevSecOps)
USER $USER

# Mở port và chạy app (Thay đổi port theo app của em)
EXPOSE 3000
CMD ["npm", "start"]