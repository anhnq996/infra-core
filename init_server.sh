#!/bin/bash

# Định nghĩa thư mục gốc
ROOT_DIR="."

echo "--- Bé đang khởi tạo cấu trúc thư mục cho cụ... ---"

# 1. Tạo các thư mục chính
mkdir -p $ROOT_DIR/core/traefik/config
mkdir -p $ROOT_DIR/core/traefik/certs
mkdir -p $ROOT_DIR/apps
mkdir -p $ROOT_DIR/scripts
mkdir -p $ROOT_DIR/configs/k9s

# 2. Tạo file cấu hình trống cho Traefik (để tránh lỗi volume)
touch $ROOT_DIR/core/traefik/config/traefik.yml
touch $ROOT_DIR/core/traefik/config/dynamic_conf.yaml
chmod 600 $ROOT_DIR/core/traefik/config/traefik.yml

# 3. Tạo file cấu hình mẫu cho k9s
cat <<EOF > $ROOT_DIR/configs/k9s/config.yml
k9s:
  refreshRate: 2
  maxRequestsPerSecond: 100
  ui:
    headless: false
    logoless: false
    crumbsless: false
EOF

# 4. Tạo thư mục project mẫu (Messenger Clone)
mkdir -p $ROOT_DIR/apps/messenger-app/data
touch $ROOT_DIR/apps/messenger-app/.env
touch $ROOT_DIR/apps/messenger-app/docker-compose.yml

# 5. Phân quyền (Tùy chỉnh nếu cụ dùng user khác)
# chown -R $USER:$USER $ROOT_DIR

# 6. Tạo file .gitignore (Chỉ tạo nếu chưa có)
if [ ! -f $ROOT_DIR/.gitignore ]; then
  cat <<EOF > $ROOT_DIR/.gitignore
.DS_Store
**/.env
**/data/
**/certs/
EOF
fi

echo "--- Xong rồi ạ! Cấu trúc đã sẵn sàng tại: $ROOT_DIR ---"
ls -R $ROOT_DIR