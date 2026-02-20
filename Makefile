# ============================================
# VPS Infra Core - Makefile (K3s + Helm)
# ============================================

.PHONY: help setup deploy-core deploy-gotalk deploy status logs

KUBECTL = kubectl
HELM    = helm

help:
	@echo ""
	@echo "╔══════════════════════════════════════════╗"
	@echo "║    VPS Infra Core - K3s Commands         ║"
	@echo "╚══════════════════════════════════════════╝"
	@echo ""
	@echo "  make setup           - Setup lần đầu sau khi clone"
	@echo "  make deploy          - Deploy toàn bộ hệ thống"
	@echo "  make deploy-core     - Deploy Traefik + Shared Services"
	@echo "  make deploy-gotalk   - Deploy GoTalk app"
	@echo "  make status          - Xem trạng thái cluster"
	@echo "  make logs-api        - Logs GoTalk API"
	@echo "  make logs-web        - Logs GoTalk Web"
	@echo "  make update-gotalk   - Pull image mới + rolling update"
	@echo ""

# ============================================
# Setup (chạy lần đầu trên server)
# ============================================
setup:
	@echo ">>> Kiểm tra kết nối K3s..."
	@$(KUBECTL) cluster-info > /dev/null || (echo "❌ Không kết nối được K3s!" && exit 1)
	@echo "✓ K3s đang chạy"
	@echo ""
	@echo ">>> Tạo namespaces..."
	$(KUBECTL) apply -f k8s/namespaces/namespaces.yaml
	@echo ""
	@echo ">>> Kiểm tra file secrets..."
	@echo "⚠️  Đảm bảo đã cập nhật base64 values trong:"
	@echo "   k8s/core/postgres/secret.yaml"
	@echo "   k8s/core/redis/secret.yaml"
	@echo "   k8s/core/minio/secret.yaml"
	@echo "   k8s/apps/gotalk/secret-api.yaml"
	@echo "   k8s/apps/gotalk/secret-web.yaml"
	@echo ""
	@echo "✅ Setup xong. Chạy: make deploy"

# ============================================
# Deploy Core Infrastructure
# ============================================
deploy-traefik:
	@echo ">>> Cấu hình Traefik (K3s built-in)..."
	$(KUBECTL) apply -f k8s/core/traefik/helmchartconfig.yaml
	$(KUBECTL) apply -f k8s/core/traefik/dashboard.yaml
	@echo "✅ Traefik đã được cấu hình"

deploy-postgres:
	@echo ">>> Deploy PostgreSQL..."
	$(KUBECTL) apply -f k8s/core/postgres/secret.yaml
	$(KUBECTL) apply -f k8s/core/postgres/helmchart.yaml
	@echo "✅ PostgreSQL đang cài đặt..."

deploy-redis:
	@echo ">>> Deploy Redis..."
	$(KUBECTL) apply -f k8s/core/redis/secret.yaml
	$(KUBECTL) apply -f k8s/core/redis/helmchart.yaml
	@echo "✅ Redis đang cài đặt..."

deploy-minio:
	@echo ">>> Deploy MinIO..."
	$(KUBECTL) apply -f k8s/core/minio/secret.yaml
	$(KUBECTL) apply -f k8s/core/minio/helmchart.yaml
	@echo "✅ MinIO đang cài đặt..."

deploy-mailpit:
	@echo ">>> Deploy Mailpit..."
	$(KUBECTL) apply -f k8s/core/mailpit/mailpit.yaml
	@echo "✅ Mailpit deployed"

deploy-core: deploy-traefik deploy-postgres deploy-redis deploy-minio deploy-mailpit
	@echo ""
	@echo "✅ Core infrastructure đang được cài đặt"
	@echo "   Có thể mất 2-3 phút để Helm charts cài xong"
	@echo "   Theo dõi: make status"

# ============================================
# Deploy GoTalk App
# ============================================
deploy-gotalk:
	@echo ">>> Deploy GoTalk App..."
	$(KUBECTL) apply -f k8s/apps/gotalk/secret-api.yaml
	$(KUBECTL) apply -f k8s/apps/gotalk/secret-web.yaml
	$(HELM) upgrade --install gotalk ./charts/gotalk \
		--namespace gotalk \
		--create-namespace \
		--wait \
		--timeout 5m
	@echo "✅ GoTalk deployed!"
	@echo "   Web: https://gotalk.anhnq.io.vn"
	@echo "   API: https://api-gotalk.anhnq.io.vn"

update-gotalk:
	@echo ">>> Rolling update GoTalk (pull latest image)..."
	$(KUBECTL) rollout restart deployment/gotalk-api -n gotalk
	$(KUBECTL) rollout restart deployment/gotalk-web -n gotalk
	$(KUBECTL) rollout status deployment/gotalk-api -n gotalk
	$(KUBECTL) rollout status deployment/gotalk-web -n gotalk
	@echo "✅ GoTalk updated!"

# ============================================
# Deploy All
# ============================================
deploy: deploy-core deploy-gotalk
	@echo ""
	@echo "🚀 Deploy hoàn tất!"
	@$(MAKE) status

# ============================================
# Status & Monitoring
# ============================================
status:
	@echo ""
	@echo "=== Namespaces ==="
	@$(KUBECTL) get namespaces infra gotalk 2>/dev/null || true
	@echo ""
	@echo "=== Pods (infra) ==="
	@$(KUBECTL) get pods -n infra 2>/dev/null || true
	@echo ""
	@echo "=== Pods (gotalk) ==="
	@$(KUBECTL) get pods -n gotalk 2>/dev/null || true
	@echo ""
	@echo "=== Ingress ==="
	@$(KUBECTL) get ingress -A 2>/dev/null || true

logs-api:
	$(KUBECTL) logs -n gotalk -l app=gotalk-api -f --tail=50

logs-web:
	$(KUBECTL) logs -n gotalk -l app=gotalk-web -f --tail=50

logs-traefik:
	$(KUBECTL) logs -n kube-system -l app.kubernetes.io/name=traefik -f --tail=50

logs-postgres:
	$(KUBECTL) logs -n infra -l app.kubernetes.io/name=postgresql -f --tail=50

# ============================================
# Cleanup
# ============================================
delete-gotalk:
	$(HELM) uninstall gotalk -n gotalk

delete-core:
	$(KUBECTL) delete -f k8s/core/ -R
	@echo "⚠️  Volumes (data) vẫn còn. Xóa thủ công nếu cần."
