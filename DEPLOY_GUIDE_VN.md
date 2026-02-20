# Hướng Dẫn Chi Tiết Deploy Hệ Thống VPS Infra Core

Tài liệu này bao gồm các bước hướng dẫn cụ thể từ lúc lấy code về máy chủ (VPS) cho đến quá trình cập nhật cấu hình biến môi trường, thiết lập Helm chart và cách sử dụng K9s để quản trị Kubernetes trên VPS.

---

## 1. Lấy Code (Pull / Clone Git)

Khi làm việc trên VPS, bạn cần kéo source code cấu hình hạ tầng mới nhất về.

```bash
# Nếu đây là lần đầu bạn deploy trên VPS
git clone <URL_CỦA_REPO> vps-infra-core
cd vps-infra-core

# Nếu thư mục `vps-infra-core` đã tồn tại và bạn muốn cập nhật code mới
cd vps-infra-core
git pull origin main
```

---

## 2. Tìm Và Đổi Tên Image Ở Đâu?

Toàn bộ thông tin từ việc lấy tên Docker Image nào cho tới chọn Tag version (`latest`, `v1...`) đều được khai báo tập trung trong file cấu hình Helm của GoTalk.

Bạn sẽ đổi tên Image tại file **`charts/gotalk/values.yaml`**:

```yaml
# Đường dẫn: vps-infra-core/charts/gotalk/values.yaml

api:
  image:
    repository: hoangtondao/gotalk-api  # <-- Thay chuỗi này bằng tên Image của BE
    tag: latest                         # <-- Phiên bản (tag) bạn muốn deploy

web:
  image:
    repository: hoangtondao/gotalk-web  # <-- Thay chuỗi này bằng tên Image của FE
    tag: latest                         # <-- Phiên bản (tag) bạn muốn deploy
```

*(Sau khi đổi chỗ này, khi deploy bằng Helm nó sẽ báo Cluster tự động pull đúng image này về chạy)*

---

## 3. Cấu Hình Biến Môi Trường (Env) Những File Nào?

Biến môi trường trên Kubernetes được chia làm **2 loại file** tùy theo mức độ bảo mật:

### A. Biến không nhạy cảm (Công khai)
Cấu hình trực tiếp tại **`charts/gotalk/values.yaml`**. File này sẽ commit thẳng lên Git.
- **API**: Kéo xuống đoạn `api: env:` để cấu hình Host, Port, CORS, URLs...
- **Web**: Kéo xuống đoạn `web: env:` để cấu hình NextJS App URL, Web Socket URL...

### B. Biến nhạy cảm (Secrets)
Các mật khẩu (`DB_PASSWORD`, `JWT_SECRET`, cấu hình email, Google Auth) **TUYỆT ĐỐI KHÔNG LƯU Ở VALUES**. Chúng được nằm ở thư mục `k8s/apps/gotalk/`.

Bạn cần copy từ các file template (.example) ra file chính:
```bash
# Đối với API (Backend)
cp k8s/apps/gotalk/secret-api.yaml.example k8s/apps/gotalk/secret-api.yaml
nano k8s/apps/gotalk/secret-api.yaml

# Đối với Web (Frontend)
cp k8s/apps/gotalk/secret-web.yaml.example k8s/apps/gotalk/secret-web.yaml
nano k8s/apps/gotalk/secret-web.yaml
```

**LƯU Ý QUAN TRỌNG VỀ SECRETS**: Tất cả các **giá trị (value)** bên trong file Secret của Kubernetes đều phải được **mã hóa Base64**.
*(Ví dụ mật khẩu của bạn là `123456`, trên VPS gõ lệnh `echo -n "123456" | base64`, màn hình sẽ in ra `MTIzNDU2`, hãy copy chữ `MTIzNDU2` này dán vào file yaml của Secret).*

---

## 4. Quá Trình Deploy Lên K3s

Sau khi đã Pull Code về, Sửa đổi tên Image và Setup toàn bộ Env. Bạn làm theo các bước:

### Cài Đặt Công Cụ Helm (Nếu VPS chưa có)
Hệ thống Deploy này sử dụng **Helm**. Nếu chạy lệnh báo lỗi `make: helm: No such file or directory`, hãy cài đặt Helm bằng cách chạy đoạn lệnh sau:
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo ./get_helm.sh
rm get_helm.sh
```

### Các Bước Deploy Chính:
```bash
# 1. Tạo các namespace cần thiết (Chỉ cần làm 1 lần)
make setup

# 2. XÁC NHẬN APPLY SECRETS LÊN CỤM
# Bạn phải chạy thủ công Apply cho các Secret nhạy cảm (Kể cả Db, Redis, App)
# Ví dụ:
kubectl apply -f k8s/apps/gotalk/secret-api.yaml
kubectl apply -f k8s/apps/gotalk/secret-web.yaml
# (Làm tương tự cho Postgres/Reids/MinIO Secret theo HD ở thư mục k8s/core/... nếu có thay đổi)

# 3. Chạy Deployment tự động
# Lệnh này sẽ dùng Helm đọc cấu hình values.yaml mới và deploy toàn bộ
make deploy-gotalk
# (Hoặc make deploy để deploy cả infra và gotalk)
```

**⚠️ Làm sao để cập nhật nếu lỡ đổi Biến Môi Trường (Env)?**
Nếu bạn vào sửa đổi file `values.yaml` (các biến thường) hoặc file chạy mã hóa base64 đưa vào trong `k8s/apps/gotalk/secret-api.yaml`/`secret-web.yaml` (các biến ẩn), thì bạn chỉ việc gõ lại đúng 1 dòng lệnh trên là đủ:
```bash
make deploy-gotalk
```
Helm rất thông minh, nó sẽ đi so sánh tự động file YAML của bạn với phiên bản đang chạy. Nếu nó thấy có sự thay đổi, nó sẽ tự update biến mới đè vào, sau đó tự động hủy mấy cái Pod cũ đi và từ từ kéo các Pod mới có cấu hình mới lên chạy thay thế!

---

## 5. Quản Trị Hệ Thống Bằng K9s

K9s là 1 terminal UI rất trực quan giúp bạn xem tình trạng của Cluster.

### A. Cấu Hình K9s
Nếu bạn cài đặt K3s trên VPS mặc định, file cấu hình Cụm (kubeconfig) nằm tại `/etc/rancher/k3s/k3s.yaml`.

```bash
# Nếu chưa cài K9s
curl -sS https://webi.sh/k9s | sh

# Để chạy được k9s, thường bạn sẽ dùng lệnh sudo hoặc export thẳng kubeconfig:
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
k9s
```

### B. Cách Xem (Cách Thao Tác Cơ Bản)
Sau khi bấm `k9s` vào terminal, một bảng điều khiển xuất hiện:

- **Đổi loại hiển thị**: Bấm `:` sau đó gõ tên loại resource muốn xem (vd: `:pods`, `:deploy`, `:svc`, `:secrets` rồi Enter). Mặc định vào sẽ là `:pods`.
- **Lọc theo Namespace**: 
  - Phím `0`: Bấm số 0 để xem tất cả Namespaces
  - Bấm phím `/` sau đó gõ `gotalk` (Tên Namespace chứa ứng dụng) -> Enter. 
- **Với từng Pod cụ thể (dùng mũi tên lên xuống để chọn):**
  - Nhấn `l` (chữ L thường): Mở xem **Logs** thực tế đang chạy. K9s sẽ auto-scroll. Bấm phím `Esc` để quay ra.
  - Nhấn `d`: **Describe** chỉ định. Xem cụ thể quá trình Image kéo về có lỗi không, Secret có bị thiếu không ➜ Rất hữu ích khi Pod mãi không chịu chạy (*CrashLoopBackOff* / *ImagePullBackOff*).
  - Nhấn `s`: **Shell** truy cập trực tiếp bằng lệnh (ssh) vào trong lòng Container đang chạy để kiểm tra file. Gõ lệnh `exit` để thoát.
  - Nhấn `ctrl` + `d`: **Delete** Xóa cái pod hiện tại. Lệnh này an toàn vì Deployment sẽ ngay lập tức tự sinh lại một pod y hệt thay thế. Rất hay dùng để "Khởi động lại (Restart)" ứng dụng bắt nó kéo env/image mới!

### C. Lên K9s Cần Thao Tác Gì Thêm Không?
**Câu trả lời là: Trừ khi sửa lỗi phát sinh khẩn cấp (debug), bạn KHÔNG NÊN sửa cấu hình trực tiếp (edit) trên K9s.**

K9s chủ yếu được dùng làm công cụ **Giám Sát (Monitoring)** và **Đọc Logs (Debugging)**. Quy trình chuẩn là:
1. Bạn đổi Image / Đổi Biến ENV ở source code (các file YAML/Values trên VPS).
2. Chạy lệnh `make deploy-gotalk` bên ngoài terminal bash.
3. Kế tiếp mở `k9s` nhấn `:pods`, đi vào namespace `gotalk`, xem cột hiển thị trạng thái của các Pod mới có sáng Xanh Lên (`Running`) hay không.
4. Bấm phím `l` để ngó Log xem FE / BE có kết nối đến CSDL thông suốt không. Mọi thứ OK thì ấn `Esc` hoặc `Ctrl + C` để thoát là xong nhiệm vụ.
