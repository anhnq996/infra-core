#!/bin/bash

# Script để tự động copy các file cấu hình mẫu (.example) sang file cấu hình thật (.yaml)

echo "🔄 Bắt đầu copy các file cấu hình secret..."

# --- Cấu hình cho Core Services ---
cp k8s/core/postgres/secret.yaml.example k8s/core/postgres/secret.yaml
echo "✅ Đã tạo file: k8s/core/postgres/secret.yaml"

cp k8s/core/redis/secret.yaml.example k8s/core/redis/secret.yaml
echo "✅ Đã tạo file: k8s/core/redis/secret.yaml"

cp k8s/core/minio/secret.yaml.example k8s/core/minio/secret.yaml
echo "✅ Đã tạo file: k8s/core/minio/secret.yaml"

cp k8s/core/traefik/dashboard.yaml.example k8s/core/traefik/dashboard.yaml
echo "✅ Đã tạo file: k8s/core/traefik/dashboard.yaml"

# --- Cấu hình cho App Services (GoTalk) ---
cp k8s/apps/gotalk/secret-api.yaml.example k8s/apps/gotalk/secret-api.yaml
echo "✅ Đã tạo file: k8s/apps/gotalk/secret-api.yaml"

cp k8s/apps/gotalk/secret-web.yaml.example k8s/apps/gotalk/secret-web.yaml
echo "✅ Đã tạo file: k8s/apps/gotalk/secret-web.yaml"

echo "------------------------------------------------------"
echo "🎉 Hoàn tất! Tất cả các file đã được chuẩn bị."
echo "⚠️  QUAN TRỌNG: Hãy mở các file .yaml vừa được tạo và điền các giá trị Base64 thật trước khi deploy nhé!"
