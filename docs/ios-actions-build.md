# 使用 GitHub Actions 构建 iOS IPA

工作流：`.github/workflows/build_ios.yml`。采用 Flutter 3.41.7、macOS 15 和 Xcode 16.4，与当前客户端依赖版本配套；保留 `pubspec.lock`，不在构建时升级依赖。

## 配置和触发

在 GitHub 仓库的 **Settings → Secrets and variables → Actions → Repository secrets** 中新增 `CLIENT_API_KEY`，值填本地 APK 命令中使用的同一个客户端网关 Key。不要将值写进 workflow、命令输入参数或源码。

然后在 **Actions → Build iOS IPA (unsigned) → Run workflow** 手动选择分支构建；推送 `v*` 标签也会触发。工作流只读取源码和上传构建产物，不会发布 Release 或上传 App Store。

构建核心命令为：

```bash
flutter build ipa \
  --release \
  --no-codesign \
  --no-pub \
  --obfuscate \
  --split-debug-info=./symbols/ios/ \
  --dart-define="CLIENT_API_KEY=${CLIENT_API_KEY}"
```

`--split-per-abi` 是 Android APK 参数，不传给 iOS。这里的 `--no-pub` 表示已在前面的步骤按锁文件安装过依赖。

## 产物

- `ChiffonMai-iOS-unsigned-<run_number>`：包含 `ChiffonMai-unsigned.ipa` 和 SHA-256 校验文件，保留 30 天。
- `ChiffonMai-iOS-symbols-<run_number>`：包含 Dart 的 `app.ios-arm64.symbols`，以及归档生成的原生 dSYM 压缩包，保留 90 天。需要自行下载并与对应 IPA 长期保存。

当前产物延续旧流程，为**未签名 IPA**，需要通过自己的签名工具签名后安装，不能直接用于 TestFlight 或 App Store。`flutter build ipa --no-codesign` 负责创建 xcarchive，后续步骤把其中的 `Runner.app` 按 `Payload/Runner.app` 结构组装成 IPA；不会忽略归档构建错误。

## 客户端凭据

当前工作流只使用 `CLIENT_API_KEY`，不再生成或导入 `lib/api/DeveloperToken.dart`。

歌曲详情自己的谱面评分与总评分、评分分布一起通过 `/api/ratings/chart/:songId` 读取，客户端不再直连 MySQL。该接口按 `levelIndex` 和带数据源前缀的 `userId` 返回对应记录，未评分时 `userRating` 为 null。

无需配置 MySQL、Redis、腾讯云、落雪 OAuth 客户端密钥或 AWMC 开发者密钥，也无需 Apple 签名证书、描述文件和 App Store Connect 密钥。数据库和上游服务的凭据由后端管理；`CLIENT_API_KEY` 继续通过 `--dart-define` 注入。

## 验证范围

Windows 开发机无法执行 Xcode 归档。修改 workflow 后可在本机检查 YAML、脚本语法、参数转义及源码依赖是否齐全；首次真正打包仍须由 GitHub 的 macOS runner 验证。

先前工作流调整的验证记录：actionlint、YAML/Bash 语法、凭据转义及应用入口的源码引用检查通过；功能注册表、AWMC NET. 响应解析、自动同步、游玩次数以及快速更新的增量比较和身份缓存共 52 项针对性用例通过。部分既有快速同步网络模拟用例仍超时，不能据此声称完整同步流程或 iOS 真机行为已验证。

谱面评分代理迁移复核：三个数据源的身份参数、单次接口读取、分数字符串兼容、未评分与接口失败处理共 6 项针对性检查通过；线上评分接口只读检查返回 HTTP 200，包含个人评分字段；移除旧凭据注入后的工作流通过 actionlint。本次没有触发 GitHub Actions 或执行 iOS 归档、真机测试。

源码引用检查中还修正了 `PortablePlayerBadge.dart` 的 4 处错误相对导入，避免应用入口在全新构建时找不到随身听依赖。

## AWMC 旧控制台退役

旧「AWMC 网关」控制台及其成绩写入、审计页面已经移除，首页、系统页、功能注册表和旧收藏也不再提供该入口。

同步线路 1、快速更新、自动同步、AWMC NET. 和独立游玩次数读取仍使用部分 AWMC 服务。这些客户端依赖保留原实现，并取消目录级 Git 忽略，避免全新检出时缺少编译源码。旧 `AwmcToken*.dart` 凭据文件继续忽略；保留的服务通过后端代理访问，不依赖客户端网关令牌。

参考：[Flutter iOS 发布文档](https://docs.flutter.dev/deployment/ios)、[Flutter 混淆与符号文件](https://docs.flutter.dev/deployment/obfuscate)、[GitHub Secrets 配置](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)。
