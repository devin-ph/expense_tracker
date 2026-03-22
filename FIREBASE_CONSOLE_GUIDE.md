# Firebase Console - Hướng dẫn Truy cập & Quản lý

## 🌐 Truy cập Firebase Console

### Bước 1: Mở Firebase Console

1. Vào https://console.firebase.google.com
2. Đăng nhập với tài khoản Google của bạn
3. Chọn project **"expense-tracker"** (hoặc tên project bạn đã tạo)

### Bước 2: Giao diện chính

```
Firebase Console
├── Build (Xây dựng)
│   ├── Authentication (Quản lý đăng nhập)
│   ├── Firestore Database (Lưu dữ liệu)
│   ├── Realtime Database
│   ├── Storage (Lưu ảnh)
│   └── Hosting
├── Analytics (Phân tích)
├── Messaging
├── Dynamic Links
└── Extensions
```

---

## 🔑 1. Quản lý Authentication (Người dùng)

### 1.1 Xem danh sách users

**Đường dẫn:** Build → **Authentication** → **Users**

**Thông tin hiển thị:**

- Email
- ID (UID)
- Created date
- Last sign-in

### 1.2 Thêm user thủ công (cho test)

1. Vào **Authentication → Users**
2. Nhấn **"Add user"** (Add User button ở góc trên)
3. Nhập Email và Password
4. Nhấn **"Add user"**

### 1.3 Xóa user

1. Nhấn menu 3 chấm (•••) bên phải user
2. Chọn **Delete**
3. Xác nhận xóa

### 1.4 Cấu hình sign-in methods

**Đường dẫn:** Authentication → **Sign-in method**

**Phương pháp có sẵn:**

- ✅ Email/Password (đã bật)
- Email link
- Phone
- Google (bật thêm)
- Facebook
- GitHub
- Twitter

---

## 💾 2. Quản lý Firestore Database

### 2.1 Xem dữ liệu

**Đường dẫn:** Build → **Firestore Database** → **Data** tab

**Cấu trúc dữ liệu:**

```
firebase (database)
└── users (collection)
    ├── [uid1] (document)
    │   ├── id: "uid1"
    │   ├── name: "Nguyễn Văn A"
    │   ├── email: "user@example.com"
    │   ├── photoUrl: "https://..."
    │   ├── createdAt: "2024-01-01T10:00:00"
    │   └── updatedAt: "2024-01-01T10:00:00"
    └── [uid2] (document)
        └── ...
```

### 2.2 Thêm dữ liệu thủ công

1. Vào **Firestore Database**
2. Nhấn **"Start collection"**
3. Nhập tên collection: **"users"**
4. Chọn **"Auto ID"** hoặc nhập ID thủ công
5. Thêm fields:
   - name (String)
   - email (String)
   - photoUrl (String)
   - createdAt (Timestamp)
   - updatedAt (Timestamp)

### 2.3 Xóa dữ liệu

1. Nhấn menu 3 chấm (•••) bên phải document
2. Chọn **Delete**

### 2.4 Cập nhật rules (Firestore Rules)

**Đường dẫn:** Firestore Database → **Rules** tab

**Ví dụ rules an toàn:**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - chỉ user đó mới có quyền
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // Transactions collection
    match /transactions/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🖼️ 3. Quản lý Storage (Lưu ảnh)

### 3.1 Xem tệp

**Đường dẫn:** Build → **Storage** → **Files**

**Cấu trúc:**

```
gs://expense-tracker-xxx.appspot.com/
└── user-avatars/
    ├── uid1/avatar.jpg
    ├── uid2/avatar.jpg
    └── ...
```

### 3.2 Cấu hình Storage Rules

**Đường dẫn:** Storage → **Rules** tab

**Ví dụ:**

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User avatars
    match /user-avatars/{uid}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.uid == uid;
    }
  }
}
```

---

## 📊 4. Analytics & Monitoring

### 4.1 Xem user activity

**Đường dẫn:** Analytics → **Dashboard**

**Thông tin:**

- Tổng users
- New users
- Active users
- Device types
- Country
- OS (Android, iOS, Web)

### 4.2 Xem error logs

**Đường dẫn:** Build → **Firestore Database** → **Monitoring** tab

---

## 🔧 5. Project Settings

### 5.1 Truy cập Project Settings

1. Nhấn icon bánh răng ⚙️ (gear icon)
2. Chọn **Project Settings**

### 5.2 Thông tin quan trọng

- **Project ID**: expense-tracker-xxx
- **Project Number**: 123456789
- **Storage Bucket**: gs://expense-tracker-xxx.appspot.com

### 5.3 Service Accounts

1. Vào **Project Settings**
2. Tab **"Service Accounts"**
3. Chọn **"Firebase Admin SDK"**
4. Chọn ngôn ngữ **"Dart"**
5. Nhấn **"Generate new key"** (nếu cần backend)

---

## 📱 6. Truy cập từ App

### Khi app gửi request lên Firebase:

```dart
// Đăng ký
await AuthNotifier().signup('user@example.com', 'password', 'Tên người dùng');
├─ Firebase lưu vào Authentication
└─ Firebase lưu vào Firestore (users collection)

// Đăng nhập
await AuthNotifier().login('user@example.com', 'password');
├─ Firebase xác thực user
└─ Lấy dữ liệu từ Firestore

// Cập nhật profile
await AuthNotifier().updateUserProfile(name: 'Tên mới', photoUrl: 'url');
├─ Cập nhật Firestore
└─ Cập nhật Authentication profile
```

### Dữ liệu hiển thị trong Console:

1. **Authentication** → Xem email, UID, created date
2. **Firestore** → Xem name, email, photoUrl, createdAt
3. **Storage** → Xem ảnh đại diện (nếu lưu)

---

## 🚨 7. Debug & Troubleshooting

### Kiểm tra user được tạo

```
Firebase Console
└── Authentication → Users
    └── Tìm email vừa đăng ký
```

### Kiểm tra dữ liệu được lưu

```
Firebase Console
└── Firestore Database → Data
    └── users collection → Tìm document
```

### Xem error logs

```
Firebase Console
└── Firestore Database → Monitoring
    └── Xem "Usage" và "Errors"
```

### Xem request logs

```bash
# Terminal: Xem Firebase emulator logs (khi phát triển locally)
firebase emulators:start
```

---

## 📈 8. Quota & Pricing

### Free Tier (Spark)

- **Authentication**: Unlimited users
- **Firestore**:
  - 50K reads/day
  - 20K writes/day
  - 1KB/day delete operations
- **Storage**: 5GB
- **Functions**: 125K invocations/month

### Chuyển sang Blaze Plan (Pay-as-you-go)

1. Firebase Console
2. Settings → **Billing**
3. Upgrade to Blaze Plan
4. Liên kết Credit Card
5. Thanh toán theo actual usage

### Tính giá:

- Firestore read: $0.06 per 100K reads
- Firestore write: $0.18 per 100K writes
- Storage: $0.18 per GB

---

## 🎯 Tóm tắt

| Tác vụ          | Đường dẫn                           |
| --------------- | ----------------------------------- |
| Xem users       | Authentication → Users              |
| Thêm user test  | Authentication → Users → Add user   |
| Xem dữ liệu app | Firestore Database → Data           |
| Xem ảnh avatar  | Storage → Files                     |
| Xem lỗi         | Firestore Database → Monitoring     |
| Cài đặt rules   | Firestore → Rules / Storage → Rules |
| Project info    | Settings → Project settings         |

---

**Mẹo:** Bookmark https://console.firebase.google.com để truy cập nhanh! 🔖
