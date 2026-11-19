# App Store 提交资料包

版本 3.0.3（60）。本目录是给 App Store Connect 用的成稿；源码说明见 `docs/app-store-review-notes.md`。

## 目录

| 文件 | 用途 |
|---|---|
| `00-reply-to-review.md` | 回复审核的开场白（可选） |
| `01-review-notes-zh.md` | **备注字段**中文成稿（填占位符后整段粘贴） |
| `02-review-notes-en.md` | 备注英文版 |
| `03-listing-zh.md` / `03-listing-en.md` | 名称、副标题、推广文本、描述、关键词、URL |
| `04-app-privacy.md` | App 隐私问卷逐项答案 |
| `05-age-rating.md` | 年龄分级问卷答案（建议 13+） |
| `06-recording-and-demo.md` | 演示账号准备 + 录屏分镜 |
| `07-release-notes.md` | 版本说明（中英） |
| `08-checklist.md` | 提交前清单与字段表 |
| `screenshots/` | 11 张模拟器截图（1320×2868） |
| `simulator-walkthrough.mp4` | 23 秒模拟器走查草稿 |
| `build/` | 未签名 IPA、SHA-256、构建说明 |

## 当前状态

- 代码已补：删除账号、评论举报、用户屏蔽、屏蔽管理；`flutter analyze` 零 error，数据源测试 30 项通过。
- iOS：3.0.3（60）已签名、校验并上传 App Store Connect，处理状态 VALID，已进入 TestFlight。**未真机验证。**
- Android：Dart/Kotlin 编译通过，release 只差 keystore 签名；已附可安装的 debug APK。
- 截图与 23 秒走查视频来自 iPhone 18 Pro Max 模拟器，不是真机；可先占位，提交前建议重拍。

## 你必须补的三样

1. 正式签名与 TestFlight 上传。
2. 演示水鱼小号 + 真机录屏链接。
3. 联系人信息，以及逐项核对隐私答案。

其余字段均可直接从本目录复制。
