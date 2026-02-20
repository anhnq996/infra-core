# VPS Infra Core

Hệ thống quản lý infrastructure tập trung cho VPS, chạy trên **K3s (Kubernetes)** với **Helm**.
Quản lý qua **k9s** (terminal UI).

---

## Cấu trúc

```
vps-infra-core/
├── charts/
│   └── gotalk/                    # Helm Chart cho GoTalk app
│       ├── Chart.yaml
│       ├── values.yaml            # Config non-sensitive (commit được)
│       └── templates/
│           ├── deployment-api.yaml
│           ├── deployment-web.yaml
│           ├── services.yaml
│           └── ingress.yaml
├── k8s/
│   ├── namespaces/
│   │   └── namespaces.yaml        # namespace: infra, gotalk
│   ├── core/
│   │   ├── traefik/
│   │   │   ├── helmchartconfig.yaml  # Override K3s built-in Traefik (Let's Encrypt)
│   │   │   └── dashboard.yaml        # Dashboard IngressRoute + Auth (gitignored)
│   │   ├── postgres/
│   │   │   ├── helmchart.yaml        # Auto install bitnami/postgresql
│   │   │   └── secret.yaml           # DB credentials (gitignored)
│   │   ├── redis/
│   │   │   ├── helmchart.yaml
│   │   │   └── secret.yaml           # (gitignored)
│   │   ├── minio/
│   │   │   ├── helmchart.yaml
│   │   │   └── secret.yaml           # (gitignored)
│   │   └── mailpit/
│   │       └── mailpit.yaml
│   └── apps/
│       └── gotalk/
│           ├── secret-api.yaml.example  # Template cho BE Secret
│           └── secret-web.yaml.example  # Template cho FE Secret
├── configs/
│   └── k9s/config.yml             # k9s config
├── .gitignore
├── Makefile
└── README.md
```

---

## Kiến trúc

```
Internet :80/:443
     │
     ▼
 [Traefik]  ← K3s built-in, Auto SSL Let's Encrypt, HTTP→HTTPS
     │
     ├─── gotalk.anhnq.io.vn      → gotalk-web  (namespace: gotalk)
     ├─── api-gotalk.anhnq.io.vn  → gotalk-api  (namespace: gotalk)
     ├─── storage.anhnq.io.vn     → minio API   (namespace: infra)
     ├─── minio.anhnq.io.vn       → minio UI    (namespace: infra)
     ├─── mail.anhnq.io.vn        → mailpit     (namespace: infra)
     └─── traefik.anhnq.io.vn     → dashboard   (namespace: kube-system)

 [infra namespace]
     ├─── postgres  (bitnami/postgresql via HelmChart CRD)
     ├─── redis     (bitnami/redis via HelmChart CRD)
     ├─── minio     (minio/minio via HelmChart CRD)
     └─── mailpit   (raw Deployment)
```

---

## Quản lý Env Vars

| Loại | Nơi lưu | Commit? |
|---|---|---|
| Non-sensitive (host, port, URL...) | `charts/gotalk/values.yaml` | ✅ |
| Sensitive (passwords, secrets...) | K8s Secret (tạo tay trên server) | ❌ |

### Phân chia cho GoTalk:

- **`values.yaml` → `api.env`**: `DB_HOST`, `REDIS_HOST`, `SMTP_HOST`, `CORS_ORIGINS`...
- **`secret-api.yaml`** (gitignored): `DB_PASSWORD`, `REDIS_PASSWORD`, `JWT_SECRET`, `GOOGLE_CLIENT_SECRET`...
- **`values.yaml` → `web.env`**: `NEXT_PUBLIC_API_URL`, `NODE_ENV`...
- **`secret-web.yaml`** (gitignored): `NEXT_PUBLIC_GOOGLE_CLIENT_ID`, `NEXT_PUBLIC_WS_URL`...

### Đặt Image Name:

```yaml
# charts/gotalk/values.yaml
api:
  image:
    repository: your-dockerhub-username/gotalk-api   # ← sửa ở đây
    tag: latest

web:
  image:
    repository: your-dockerhub-username/gotalk-web   # ← sửa ở đây
    tag: latest
```

---

## 🚀 Deploy lên server (từ đầu)

### Yêu cầu
- K3s đã cài trên VPS
- Port 80, 443 mở
- Tất cả domain trỏ A record về IP server

### Bước 1: Clone repo

```bash
git clone <repo-url> vps-infra-core && cd vps-infra-core
```

### Bước 2: Tạo namespace

```bash
make setup
# hoặc: kubectl apply -f k8s/namespaces/namespaces.yaml
```

### Bước 3: Tạo Secrets (tạo 1 lần, không bao giờ commit)

```bash
# --- Shared Services ---
# PostgreSQL
cp k8s/core/postgres/secret.yaml.example k8s/core/postgres/secret.yaml
# Điền base64 values: echo -n "password" | base64
nano k8s/core/postgres/secret.yaml
kubectl apply -f k8s/core/postgres/secret.yaml

# Redis
cp k8s/core/redis/secret.yaml.example k8s/core/redis/secret.yaml
nano k8s/core/redis/secret.yaml
kubectl apply -f k8s/core/redis/secret.yaml

# MinIO
cp k8s/core/minio/secret.yaml.example k8s/core/minio/secret.yaml
nano k8s/core/minio/secret.yaml
kubectl apply -f k8s/core/minio/secret.yaml

# --- GoTalk App ---
# BE Secret
cp k8s/apps/gotalk/secret-api.yaml.example k8s/apps/gotalk/secret-api.yaml
nano k8s/apps/gotalk/secret-api.yaml
kubectl apply -f k8s/apps/gotalk/secret-api.yaml

# FE Secret
cp k8s/apps/gotalk/secret-web.yaml.example k8s/apps/gotalk/secret-web.yaml
nano k8s/apps/gotalk/secret-web.yaml
kubectl apply -f k8s/apps/gotalk/secret-web.yaml

# Traefik Dashboard Auth
cp k8s/core/traefik/dashboard.yaml.example k8s/core/traefik/dashboard.yaml
# Tạo hash: htpasswd -nB admin | sed -e s/\\$/\\$\\$/g | base64
nano k8s/core/traefik/dashboard.yaml
kubectl apply -f k8s/core/traefik/dashboard.yaml
```

### Bước 4: Cập nhật image name

```bash
# Sửa repository trong values.yaml
nano charts/gotalk/values.yaml
```

### Bước 5: Deploy

```bash
make deploy          # Deploy tất cả
make status          # Kiểm tra
k9s                  # Quản lý qua TUI
```

---

## � Lệnh thường dùng

```bash
make help            # Xem tất cả lệnh
make deploy          # Deploy toàn bộ
make deploy-core     # Chỉ shared services (postgres, redis, minio, mailpit)
make deploy-gotalk   # Chỉ GoTalk app
make update-gotalk   # Rolling update (sau khi push image mới)
make status          # Xem trạng thái pods
make logs-api        # Logs BE
make logs-web        # Logs FE
make logs-traefik    # Logs Traefik
k9s                  # Terminal UI đầy đủ
```

---

## � CI/CD Flow (thêm app mới)

```
1. Push code → GitHub Actions build image
2. Push image lên Docker Hub: user/gotalk-api:v1.2.3
3. Cập nhật tag trong values.yaml:
     api.image.tag: v1.2.3
4. git push → chạy: make update-gotalk
```
