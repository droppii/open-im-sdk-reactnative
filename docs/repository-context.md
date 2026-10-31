# Ngữ cảnh repository — open-im-sdk-reactnative

Wrapper React Native cho OpenIM native SDK.

## 1. Trách nhiệm và luồng xử lý

TypeScript public API chuyển lời gọi và sự kiện qua bridge Android/iOS; binary native tương ứng với phiên bản core và protocol. example cung cấp host kiểm thử.

Giữ kiểu tham số, mã sự kiện, thread/lifecycle và lỗi native nhất quán giữa hai nền tảng. Không chỉ nâng package TypeScript khi thay ABI native; kiểm tra binary và core đi cùng nhau.

## 2. Điểm bắt đầu trong mã

- [src](../src).
- [android](../android).
- [ios](../ios).
- [example](../example).
- [package.json](../package.json).
- [.circleci](../.circleci).

Đọc hướng dẫn tại thư mục con trước khi sửa module tương ứng. Đối chiếu hợp đồng và nơi gọi khi thay đổi API, dữ liệu hoặc thư viện dùng chung.

## 3. Toolchain và kiểm chứng

Phiên bản và lệnh được quản lý trong manifest của từng package; giữ lockfile đang được đường build sử dụng. Với monorepo, chạy tại đúng package hoặc qua workspace. Không nâng toolchain chỉ để làm một lệnh cũ chạy được.

| Manifest | Toolchain được khai báo |
| --- | --- |
| [example/package.json](../example/package.json) | node >=16; react 18.2.0; react-native 0.72.4 |
| [package.json](../package.json) | yarn@1.22.15; node >= 16.0.0; react 18.2.0; react-native 0.70.5; typescript ^5.0.2 |
| [website/package.json](../website/package.json) | node >=20.0; react ^19.0.0; typescript ~5.6.2 |

| Mục đích | Thư mục chạy | Lệnh | Điều kiện và tác động |
| --- | --- | --- | --- |
| typecheck | `.` | `yarn run typecheck` | Kiểm tra tĩnh; không thay thế kiểm thử hành vi. Script: `tsc --noEmit`. |
| lint | `.` | `yarn run lint` | Kiểm tra tĩnh; không thay thế kiểm thử hành vi. Script: `eslint "**/*.{js,ts,tsx}"`. |
| test | `.` | `yarn run test` | Kiểm tra fixture, hook và môi trường trước khi chạy; không mặc định là test cô lập. Script: `jest`. |
| typecheck | `website` | `yarn run typecheck` | Kiểm tra tĩnh; không thay thế kiểm thử hành vi. Script: `tsc`. |
| build | `website` | `yarn run build` | Tạo artifact; có thể tải dependency hoặc gọi nguồn dữ liệu khi build, không đồng nghĩa đã deploy. Script: `docusaurus build`. |

Ghi kết quả và phạm vi thực sự đã chạy trong PR. Không ghi build, lint hoặc test thành công khi mới đọc cấu hình hay khi script không thực thi assertion.

## 4. Cấu hình và phát hành

Đường tự động hóa được xác định trong các workflow sau. Điều kiện branch/tag/path quyết định lúc chạy; bước phát hành cần được đọc cùng quyền và môi trường của job.

| Workflow | Điều kiện kích hoạt |
| --- | --- |
| [.github/workflows/deploy-docs.yml](../.github/workflows/deploy-docs.yml) | push; branches=main; paths=website/**, .github/workflows/deploy-docs.yml; workflow_dispatch |

Pipeline ngoài GitHub Actions: [.circleci/config.yml](../.circleci/config.yml).

Dùng credential được cấp cho đúng môi trường. Không lưu secret hoặc dữ liệu cá nhân vào mã, tài liệu, ảnh chụp hay log. Migration, seed, publish, gửi thông báo và rollout là thao tác có tác động; chỉ thực hiện trong phạm vi công việc và môi trường đã được giao. Phiên bản đang phục vụ cần được xác định từ artifact/deployment, không chỉ từ default branch.

## 5. Tiêu chuẩn chung và duy trì

Áp dụng [Engineering Standards](https://github.com/droppii/engineering-knowledge/tree/docs/repository-context-pilot/handbook/standards/standards.md), [Principles](https://github.com/droppii/engineering-knowledge/tree/docs/repository-context-pilot/handbook/principles/principles.md) và [AI Context](https://github.com/droppii/engineering-knowledge/tree/docs/repository-context-pilot/handbook/ai-context/README.md). Cấu trúc đang có giải thích cách tìm mã; những phần chưa theo tiêu chuẩn cần được cải thiện khi sửa, không trở thành ngoại lệ mặc định.

Cập nhật tài liệu này trong cùng thay đổi khi module, toolchain, public contract, pipeline hoặc điều kiện kiểm thử thay đổi. Quyết định đặc thù cần được ghi ở repository; kiến thức và tiêu chuẩn dùng chung được duy trì tại Engineering Knowledge.
