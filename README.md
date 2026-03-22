# Ứng dụng quản lý chi tiêu cá nhân xây dựng bằng Flutter - Nhóm G3C3

## 📱 Bảng phân chia công việc

| Màn hình            | Phụ trách           | Tính năng          |
| ------------------- | ------------------- | ------------------ |
| **Home**            | Lê Tiến Minh        | Màn hình chính     |
| **Transactions**    | Đinh Phương Ly      | Lịch sử giao dịch  |
| **Add Transaction** | Trần Quang Quân     | Thêm giao dịch mới |
| **Statistics**      | Phạm Hoàng Thế Vinh | Thống kê           |
| **Login/Profile**   | Phạm Ngọc Minh Nam  | Đăng nhập/Hồ sơ    |

## 🚀 Cài đặt dự án

1. **Clone repository**

   ```bash
   git clone https://github.com/devin-ph/expense_tracker.git
   cd expense_tracker
   ```

2. **Cài dependencies**

   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

## � Cài đặt tính năng Chat (FastAPI + Groq)

### Yêu cầu tiên quyết

- Python 3.8 trở lên
- Tài khoản Groq API (miễn phí)

### Bước 1: Lấy Groq API Key

1. Truy cập [https://console.groq.com/keys](https://console.groq.com/keys)
2. Đăng ký/Đăng nhập bằng tài khoản Google hoặc Email
3. Tạo API Key mới ở mục "API Keys"
4. Copy API Key (dạng `gsk_...`)

### Bước 2: Cấu hình biến môi trường

1. Tạo file `.env` ở **thư mục gốc** của dự án (cùng cấp với `PastAPI.py`):

   ```bash
   # Ở thư mục expense_tracker, tạo file .env
   echo GROQ_API_KEY=your_api_key_here > .env
   ```

2. Hoặc mở file `.env` bằng editor và thêm:

   ```
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxx
   ```

   ⚠️ **Lưu ý**: Thay `gsk_xxxxxxxxxxxxxxxxxx` bằng API key thực tế từ Groq

3. Xác nhận file `.env` đã được thêm vào `.gitignore` (để chắc chắn không đẩy API key lên GitHub)

### Bước 3: Cài đặt thư viện Python

```bash
# Cài đặt dependencies từ requirements.txt
pip install -r requirements.txt
```

Hoặc cài thủ công:

```bash
pip install fastapi uvicorn httpx python-dotenv pydantic
```

### Bước 4: Khởi động FastAPI backend

Chạy một trong các lệnh sau tùy theo nhu cầu:

**Chế độ dev (auto-reload khi code thay đổi):**

```bash
python -m uvicorn PastAPI:app --reload --host 127.0.0.1 --port 8000
```

**Chế độ production:**

```bash
python -m uvicorn PastAPI:app --host 0.0.0.0 --port 8000
```

✅ Nếu thấy `Uvicorn running on http://127.0.0.1:8000` - backend đã sẵn sàng!

### Bước 5: Chạy Flutter app

Mở terminal khác và chạy:

```bash
flutter run
```

### 🎯 Sử dụng Chat feature

1. Mở ứng dụng hoặc nhấn vào icon chat ở góc phải màn hình
2. Chat với trợ lý:
   - Gõ giao dịch: `ăn trưa 200k`, `xăng 100k`, `lương 10 triệu`
   - Hỏi thông tin: `còn bao nhiêu tiền`, `hôm nay chi bao nhiêu`
3. Trợ lý sẽ tự động lưu giao dịch hoặc trả lời câu hỏi

### 🔧 Troubleshooting

**Lỗi: "Chưa cấu hình GROQ_API_KEY"**

- ✔️ Kiểm tra file `.env` có tồn tại trong thư mục dự án
- ✔️ Kiểm tra format: `GROQ_API_KEY=gsk_...` (không có dấu nháy)
- ✔️ Khởi động lại FastAPI: `Ctrl+C` rồi chạy lại command khởi động

**Lỗi: "Không kết nối được FastAPI"**

- ✔️ Kiểm tra FastAPI đã chạy trên port 8000: `http://127.0.0.1:8000/docs`
- ✔️ Trên Android/Web phải chạy trên `localhost:8000` không phải `10.0.2.2`

**Lỗi: "ModuleNotFoundError: No module named 'dotenv'"**

- ✔️ Chạy: `pip install python-dotenv` hoặc `pip install -r requirements.txt`

## �📋 Cấu trúc dự án

```
lib/
├── config/              # Configuration
│   ├── theme.dart       # Themes
│   ├── constants.dart   # Constants
│   └── default_categories.dart
├── models/              # Data models
├── providers/           # State management
├── screens/             # App screens
│   ├── home/
│   ├── transactions/
│   ├── add_transaction/
│   ├── statistics/
│   └── auth/
├── widgets/             # Reusable widgets
└── main.dart
```

## 🤝 Thành viên nhóm

- **Lê Tiến Minh** - Home Screen
- **Đinh Phương Ly** - Transactions Screen
- **Trần Quang Quân** - Add Transaction
- **Phạm Hoàng Thế Vinh** - Statistics
- **Phạm Ngọc Minh Nam** - Auth & Profile
