# Ứng dụng admin quản lý người dùng (MongoDB)

Ứng dụng Flutter chạy trên web và điện thoại. Admin đăng nhập rồi thêm, xem, tìm kiếm, sửa, xóa người dùng và chọn ảnh đại diện. API Node.js kết nối MongoDB bằng Mongoose; schema người dùng nằm trong `server/models/user.js`.

## Cấu trúc dữ liệu

Collection `users` trong database `giuaki2`:

| Trường | Ý nghĩa |
| --- | --- |
| `email` | Email duy nhất, dùng để đăng nhập |
| `fullName` | Họ tên |
| `passwordHash` | Mật khẩu được băm bằng bcrypt; không lưu mật khẩu gốc |
| `role` | `admin` hoặc `user` |
| `avatar`, `avatarContentType` | Dữ liệu ảnh và loại ảnh trong MongoDB, tối đa 5 MB |
| `createdAt`, `updatedAt` | Thời điểm tạo/cập nhật |

Ảnh được trả qua API có kiểm tra quyền admin. Các thao tác quản lý tài khoản cũng chỉ dành cho admin. MongoDB tạo unique index cho `email`.

## Chuẩn bị và chạy API

1. Cài Node.js và chạy MongoDB cục bộ hoặc chuẩn bị MongoDB Atlas URI.
2. Sao chép `server/.env.example` thành `server/.env`. Điền `MONGODB_URI`, `JWT_SECRET` (chuỗi ngẫu nhiên ít nhất 32 ký tự), và tùy chọn `MONGODB_DB`, `PORT`.
3. Từ thư mục `server`, chạy:

```powershell
npm.cmd install
node scripts/create-admin.js admin@example.com "matkhau123" "Quản trị viên"
npm.cmd start
```

Tạo admin một lần trước khi đăng nhập. Chạy lại lệnh `create-admin` với cùng email sẽ cập nhật tên và mật khẩu của admin.

Để dùng cùng dữ liệu với Compass, cấu hình server và Compass bằng cùng URI Atlas. `MONGODB_URI` chỉ chứa URI sau một dấu `=`; thay phần mật khẩu mẫu bằng mật khẩu database user. `MONGODB_DB=giuaki2` chọn database, collection người dùng là `users`.

## Chạy Flutter

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Khi build web và chạy `flutter build web`, API tự phục vụ thư mục `build/web` tại `http://localhost:3000`; khi đó không cần `API_BASE_URL`.

Android emulator mặc định gọi `http://10.0.2.2:3000`. Với điện thoại thật, truyền địa chỉ LAN của máy chạy API:

```powershell
flutter run -d device-id --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

Đảm bảo điện thoại và máy chủ cùng mạng và cổng 3000 được phép truy cập. Khi triển khai thật, dùng HTTPS cho API.

## Kiểm tra

```powershell
cd server
npm.cmd run check
npm.cmd test
cd ..
flutter analyze
flutter test
flutter build web
```

Kiểm thử API dùng một MongoDB thử riêng, kiểm tra đăng nhập, CRUD, email trùng, đổi mật khẩu, bảo vệ admin và nội dung ảnh. Lần chạy đầu có thể tải binary MongoDB phục vụ kiểm thử.

Ứng dụng trước đây dùng Firebase; phần Firebase đã được gỡ khỏi mã nguồn. Dữ liệu sản phẩm cũ không phù hợp với collection người dùng mới, nên không tự động chuyển sang MongoDB.
