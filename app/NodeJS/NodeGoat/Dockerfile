# ==========================================
# STAGE 0: BUILD
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# Trỏ đúng đường dẫn vào thư mục chứa package.json của NodeGoat
COPY app/NodeJS/NodeGoat/package*.json ./

# (Mẹo nhỏ: Sửa --production thành --omit=dev để hết cảnh báo màu vàng của npm)
RUN npm install --omit=dev --no-cache

# ==========================================
# STAGE 1: PRODUCTION
# ==========================================
FROM node:18-alpine

ENV USER=node
ENV WORKDIR=/home/node/app

WORKDIR $WORKDIR

COPY --from=builder /usr/src/app/node_modules ./node_modules

# Trỏ đúng đường dẫn để copy mã nguồn của NodeGoat vào image
COPY --chown=node:node app/NodeJS/NodeGoat/ .

USER $USER

EXPOSE 4000 
# (NodeGoat mặc định chạy port 4000, em có thể check lại trong config)
CMD ["npm", "start"]