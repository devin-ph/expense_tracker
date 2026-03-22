# Hướng dẫn Setup Firebase cho Expense Tracker

## 📋 Bước 1: Tạo Firebase Project

### 1.1 Truy cập Firebase Console

1. Mở https://console.firebase.google.com
2. Đăng nhập với tài khoản Google (nếu chưa có tài khoản, hãy tạo mới)

### 1.2 Tạo Project mới

1. Nhấn **"Create a project"** hoặc **"Add project"**
2. Nhập tên project: **"expense-tracker"** (hoặc tên khác)
3. Chọn **Accept the Firebase terms** checkbox
4. Nhấn **"Create project"**
5. Chọn **"Enable Google Analytics"** (tùy chọn)
6. Chọn **"Create project"**
7. Ngợi chờ quá trình tạo hoàn tất (~1 phút)

## 🔐 Bước 2: Bật Firebase Authentication

### 2.1 Kích hoạt Email/Password Authentication

1. Từ Firebase Console, chọn project vừa tạo
2. Vào **Build → Authentication**
3. Nhấn **"Get Started"** nếu lần đầu
4. Chọn **"Email/Password"**
5. Kích hoạt **"Email/Password"** toggle
6. Kích hoạt **"Email link (passwordless sign-in)"** (tùy chọn)
7. Nhấn **"Save"**

### 2.2 Kích hoạt Google Sign-In (tùy chọn)

1. Ở trang Authentication, chọn **Sign-in method**
2. Chọn **"Google"**
3. Kích hoạt toggle
4. Chọn project support email
5. Nhấn **"Save"**

## 📱 Bước 3: Cấu hình Flutter với Firebase

### 3.1 Cài đặt Firebase CLI (nếu chưa có)

```bash
# Windows
choco install firebase-cli

# hoặc tải từ https://firebase.google.com/download/cli
```

### 3.2 Đăng nhập Firebase CLI

```bash
firebase login
```

- Mở browser và đăng nhập Google account
- Xác nhận các quyền

### 3.3 Kết nối Flutter Project với Firebase

```bash
# Di chuyển vào thư mục project
cd c:\Users\binh1\StudioProjects\expense_tracker

# Kết nối Firebase
flutterfire configure

# Chọn project vừa tạo
# Chọn các platform: android, ios, web (tùy theo nhu cầu)
```

**Kết quả:** Lệnh này sẽ tự động tạo file cấu hình Firebase (google-services.json cho Android, GoogleService-Info.plist cho iOS)

### 3.4 Cài đặt dependencies

```bash
flutter pub get
```

## 🗄️ Bước 4: Thiết lập Cloud Firestore (Optional - để lưu user data)

### 4.1 Tạo Firestore Database

1. Từ Firebase Console, chọn **Build → Firestore Database**
2. Nhấn **"Create database"**
3. Chọn **"Start in test mode"** (cho phát triển)
4. Chọn vị trí gần nhất (ví dụ: asia-southeast1 - Singapore)
5. Nhấn **"Create"**

### 4.2 Thiết lập Collection Users (tuỳ chọn)

```
Collection: users
Documents: auto-generated
Fields:
  - name: string
  - email: string
  - photoUrl: string (optional)
  - createdAt: timestamp
  - updatedAt: timestamp
```

## 🔑 Bước 5: Lấy Configuration Keys

### 5.1 Lấy Web API Key (nếu cần)

1. Vào **Project Settings** (icon bánh răng)
2. Chọn tab **"Service Accounts"**
3. Chọn **"Firebase Admin SDK"**
4. Chọn **"Python"** → **"Generate new private key"** (để reference)

### 5.2 Lấy Web Config (nếu cần deploy web)

1. Vào **Project Settings**
2. Chọn ứng dụng web của bạn
3. Sao chép **firebaseConfig**

## ⚠️ Bước 6: Cài đặt Firestore Security Rules (cho production)

### 6.1 Rules cho test mode (tạm thời):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Cho phép mọi người đọc và viết (CHỈ DÙNG CHO TEST)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 6.2 Rules an toàn hơn (recommended):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{uid} {
      // Chỉ user đó mới có thể đọc/viết dữ liệu của họ
      allow read, write: if request.auth.uid == uid;
    }

    // Transactions collection
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🎯 Công dụng chính của Firebase

| Chức năng                | Mục đích                                              |
| ------------------------ | ----------------------------------------------------- |
| **Firebase Auth**        | Quản lý đăng ký, đăng nhập, xác thực người dùng       |
| **Cloud Firestore**      | Lưu dữ liệu người dùng (profile), giao dịch, ví, v.v. |
| **Firebase Storage**     | Lưu ảnh đại diện người dùng                           |
| **Firebase Realtime DB** | Đồng bộ dữ liệu real-time (tuỳ chọn)                  |
| **Firebase Analytics**   | Theo dõi người dùng, hành vi (tuỳ chọn)               |

---

## 💾 Dữ liệu sẽ được lưu ở đâu?

- **Google Servers** (an toàn trên cloud)
- **Tự động đồng bộ** giữa các thiết bị
- **Free tier**: 1GB storage, 50K reads/day, 20K writes/day
- **Giá thành**: Tính theo actual usage (rất rẻ cho ứng dụng nhỏ)

---

## ✅ Kiểm tra setup

Sau khi hoàn tất tất cả bước:

1. **Kiểm tra file sinh ra:**
   - Android: `android/app/src/main/res/values/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

2. **Test login:**

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Đọc user
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    print('User is currently signed out!');
  } else {
    print('User is signed in! ${user.email}');
  }
});
```

3. **Chạy app:**

```bash
flutter run
```

---

## 🆘 Lỗi thường gặp

### "firebase_core not found"

```bash
flutter clean
flutter pub get
flutter run
```

### "google-services.json not found"

- Chạy lại: `flutterfire configure`
- Cuối cùng chạy `flutter clean` rồi `flutter pub get`

### "Firestore permission denied"

- Kiểm tra Firestore Security Rules ở Firebase Console
- Thay đổi từ "test mode" thành rules an toàn

---

**Sau khi hoàn tất setup, app sẽ tự động kết nối Firebase!** 🚀
