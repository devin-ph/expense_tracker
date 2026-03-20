# Ứng dụng quản lý chi tiêu cá nhân xây dựng bằng Flutter - Nhóm G3C3

## 📱 Bảng phân chia công việc

| Màn hình | Phụ trách | Tính năng |
|--------|-----------|----------|
| **Home** | Lê Tiến Minh | Màn hình chính |
| **Transactions** | Đinh Phương Ly | Lịch sử giao dịch |
| **Add Transaction** | Trần Quang Quân | Thêm giao dịch mới |
| **Statistics** | Phạm Hoàng Thế Vinh | Thống kê |
| **Login/Profile** | Phạm Ngọc Minh Nam | Đăng nhập/Hồ sơ |

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

## 📋 Cấu trúc dự án

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