# Ứng dụng admin quản lý người dùng (MongoDB)

Ứng dụng Flutter chạy trên web và điện thoại. Admin đăng nhập rồi thêm, xem, tìm kiếm, sửa, xóa người dùng và chọn ảnh đại diện. API Node.js kết nối MongoDB bằng Mongoose; schema người dùng nằm trong `server/models/user.js`.

## Cấu trúc dữ liệu

Collection `users` trong database `giuaki2`:

| Trường | Ý nghĩa |
| --- | --- |
| `email` | Email người dùng, không trùng lặp |
| `matkhau` | Mật khẩu được băm bằng bcrypt |
| `hoten` | Họ tên |
| `hinhanh` | Ảnh dạng chuỗi Data URI Base64, tối đa 5 MB trước khi mã hóa |

Database chỉ lưu đúng bốn trường trên cùng `_id` do MongoDB tự sinh; không có `role`, timestamps hoặc `__v`. Giao diện che mật khẩu khi hiển thị danh sách.

Tài khoản admin có sẵn: **`admin` / `admin123`**, cấu hình tại `server/admin-account.js`, chỉ dùng đăng nhập và quản lý người dùng. Admin không được lưu trong MongoDB. Các bản ghi trong collection `users` đều là người dùng được quản lý, không thể đăng nhập phân hệ admin. Admin vẫn đăng nhập được khi collection rỗng.

## Chuẩn bị và chạy API

1. Cài Node.js và chạy MongoDB cục bộ hoặc chuẩn bị MongoDB Atlas URI.
2. Sao chép `server/.env.example` thành `server/.env`. Điền `MONGODB_URI`, `JWT_SECRET` (chuỗi ngẫu nhiên ít nhất 32 ký tự), và tùy chọn `MONGODB_DB`, `PORT`.
3. Từ thư mục `server`, chạy:

```powershell
npm.cmd install
npm.cmd start
```

Mở `http://localhost:3000` và đăng nhập bằng `admin` / `admin123`.

## File cơ sở dữ liệu để nộp

`database/users.json` có hai bản ghi mẫu, mỗi bản ghi chỉ gồm `email`, `matkhau`, `hoten`, `hinhanh`. Nhập file bằng chức năng Import JSON của Compass hoặc chạy trong thư mục `server`:

```powershell
npm.cmd run import:db
```

File chỉ chứa người dùng mẫu, không chứa tài khoản admin. Dữ liệu này được đưa lên database khi Bảo chủ động nhập.

Sau khi nhập dữ liệu để demo, xuất lại file CSDL dùng để nộp:

```powershell
npm.cmd run export:db
```

Lệnh xuất ghi `database/users.json` với đúng bốn trường, gồm cả dữ liệu hình ảnh. Bài nộp kèm file này và link video demo đăng nhập, thêm/hiển thị/sửa/xóa trên web, chọn ảnh và hiển thị thông tin trên điện thoại.

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

Kiểm thử API dùng một MongoDB thử riêng, kiểm tra admin đăng nhập độc lập với CSDL, CRUD, email trùng, đổi mật khẩu và nội dung ảnh. Lần chạy đầu có thể tải binary MongoDB phục vụ kiểm thử.

Ứng dụng trước đây dùng Firebase; phần Firebase đã được gỡ khỏi mã nguồn. Dữ liệu sản phẩm cũ không phù hợp với collection người dùng mới, nên không tự động chuyển sang MongoDB.
