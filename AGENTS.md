# Hướng dẫn làm việc — open-im-sdk-reactnative

## Ngữ cảnh Engineering

Wrapper React Native cho OpenIM native SDK.

Đọc [ngữ cảnh repository](docs/repository-context.md) để chọn đúng module, toolchain, kiểm tra và đường phát hành. Đọc hướng dẫn thư mục con khi đi vào phạm vi tương ứng.

Chuẩn dùng chung: [AI Context](https://github.com/droppii/engineering-knowledge/tree/docs/repository-context-pilot/handbook/ai-context/README.md) và [Standards](https://github.com/droppii/engineering-knowledge/tree/docs/repository-context-pilot/handbook/standards/standards.md). Ghi revision đã dùng và kết quả kiểm chứng trong PR; cập nhật ngữ cảnh cùng mã.

Giữ kiểu tham số, mã sự kiện, thread/lifecycle và lỗi native nhất quán giữa hai nền tảng. Không chỉ nâng package TypeScript khi thay ABI native; kiểm tra binary và core đi cùng nhau.
