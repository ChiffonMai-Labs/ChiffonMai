# 提交清单

## 已有

- [x] `01-review-notes-zh.md`：可直接粘贴的中文备注（含 6 项）
- [x] `02-review-notes-en.md`：英文备注
- [x] `03-listing-zh.md` / `03-listing-en.md`：名称、副标题、推广文本、描述、关键词、URL、类别
- [x] `04-app-privacy.md`：App 隐私问卷答案
- [x] `05-age-rating.md`：年龄分级答案
- [x] `06-recording-and-demo.md`：录屏分镜与演示账号准备
- [x] `07-release-notes.md`：版本说明
- [x] `screenshots/`：11 张 1320×2868 模拟器截图（可先上传占位，真机重录后替换）
- [x] `build/ChiffonMai-3.0.3-59-unsigned.ipa` + SHA-256：iOS 无签名归档

## 必须由你完成

- [x] 用正式证书签名并上传 TestFlight（构建 60，Delivery UUID `8fbf1409-…`）
- [ ] 在 App Store Connect → TestFlight 添加内部测试员，真机安装构建 60。
- [ ] 真机（最新 iOS）完整走查：引导、登录、拉取、评论、举报、屏蔽、删除账号。
- [ ] 注册演示用水鱼小号，按 `06-recording-and-demo.md` 设置并验证。
- [ ] 真机录屏，按分镜执行，上传并取得链接。
- [ ] 把演示账号、密码、录屏链接填进备注与 App Store Connect 字段。
- [ ] 填写 App Store Connect 的联系人姓名、邮箱、电话。
- [ ] 逐项核对 `04-app-privacy.md` 与真实网络流量。
- [ ] 替换模拟器截图为真机截图（至少 6.9 英寸一套）。
- [ ] 处理构建警告：启动图仍是默认占位图（不阻断，但建议换）。
- [ ] Android（可选）：放回 `android/key.properties` 与 keystore 后再跑 release；编译环境已修好，当前仅卡签名。

## App Store Connect 字段

| 字段 | 值 |
|---|---|
| 名称 | ChiffonMai |
| 副标题 | 舞萌 DX 曲库与成绩工具箱 |
| 类别 | 工具，次要：音乐 |
| 价格 | 免费 |
| 地区 | 所有地区 |
| 年龄分级 | 13+ |
| 隐私政策 | https://chiffonmai.cloud/privacy |
| 技术支持 | https://chiffonmai.cloud/ |
| 营销 URL | https://chiffonmai.cloud/ |
| 版权 | © 2026 ChiffonOwO |
| 需要登录 | 是 |
| 演示账号 | 见 `06-recording-and-demo.md` |

## 备注

- 无内购，不需要提交 IAP。
- 无广告、无 ATT 弹窗。
- 账号由第三方查分器创建，App 内提供注册引导与删除账号。
