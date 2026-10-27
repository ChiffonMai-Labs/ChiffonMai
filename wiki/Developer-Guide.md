# 客户端开发者指南

当前源码版本 **2.9.0+52**；本轮核对环境为 Flutter 3.41.7 stable、Dart 3.11.5。pubspec 的 Dart 下限不代表任意旧版 Flutter 都支持当前代码，请使用兼容 SDK 和项目锁定依赖。

## 仓库范围与结构

仓库仅追踪 Flutter 客户端、平台工程、资源、必要回归检查及客户端文档。服务端源码、配置、数据、测试、部署资料和凭据保留在受保护的本地环境，不纳入 Git。

| 目录 | 内容 |
| --- | --- |
| `lib/page` | AppShell、六类导航承载页与功能页面 |
| `lib/manager` | 数据源管理、曲库与 maidata |
| `lib/service` | 账号、同步、备份、缓存与业务服务 |
| `lib/widgets` | 共享布局、统计动画、导出预览与引导组件 |
| `lib/utils` | 主题、偏好、数据转换与导出路径 |
| `android` / `ios` | 客户端平台工程 |
| `assets` | 客户端图片、字体与本地资源 |
| `test` | 保留的业务与关键回归检查 |

项目协作与易错点以根目录 [AGENTS.md](../AGENTS.md) 为准。

## 依赖与构建

```sh
flutter pub get
flutter run -d <设备ID>
flutter build apk --release
```

发布签名必须使用正式 keystore 和本地 `android/key.properties`；缺少签名资料时不能回退到 debug 签名。不要改动 applicationId、单实例启动、返回手势防护或本地通道名称。

`simai_flutter` 当前依赖解析配合锁定的 Flame 1.37.0；不要随意移除该版本锁定。谱面播放页保持竖屏和异步退出保护。iOS 构建见 [工作流说明](../docs/ios-actions-build.md)。

## 状态与数据约定

- `FeatureRegistry.sections` 是功能目录与搜索路径的统一来源；新增入口需要同步 Hub、首页分发、收藏与数量断言。
- 账号身份与成绩按来源、账号隔离；异步结果必须校验当前请求和 mounted，旧结果不能覆盖新账号。
- 登录凭据、个人 key、机台自动同步身份使用 `SecureCredentialStore`，不写入明文备份。
- `DataBackupService` v3 导出偏好与限定范围的用户文件，排除可重建缓存。`UserFileBackupService` 校验相对路径并处理文件回滚和路径改写。
- 恢复后重载偏好与用户数据单例，避免旧内存数据覆盖恢复结果；历史文件由 `ChartHistoryStore` 管理。
- maidata 全量内容在应用文档目录 JSON 中持久化，数量按曲目统计；`CacheManagementService` 向 Hub 与首页提供基础量刷新状态。
- `LogExportService` 维护有界、脱敏的近期日志及会话尾部文件；应用内日志不能替代 Android 原生 logcat。

## UI 与导出

普通页面使用 PageTopBar，处理 SafeArea 和键盘；优先平面分组布局与主题描边。滚动文案复用 MarqueeText，进度复用 SmoothLinearProgressIndicator。难度名称与索引转换走 ChartDifficulty，配色复用 AppColors／ColorUtil。

所有用户导出统一通过 ExportPathUtil；maidata 文本按 UTF-8 编码，AstroDX `.adx` 内按曲名套一层文件夹。收藏夹按内容校验交换格式。

## 共享组件与贡献约定

- 全屏背景先铺主题 surface，再放异步背景层，避免首帧闪黑；默认不让键盘挤压背景，输入内容单独避让。
- 滚动列表内的卡片用自身 Material 承载背景与交互，避免 Ink 装饰留在祖先图层造成拖影；普通分组优先平面布局。
- 曲绘使用已有组件和公共路径规则，保持本地、数据源与默认图的兜底顺序，不在新页面手工拼多套图片地址。
- 网络请求复用 ApiClient，接口地址集中在 ApiUrls。错误与日志必须脱敏，客户端不携带生产运维凭据。
- 新功能先明确数据归属和状态生命周期，再接入目录、页面分发与收藏。不要恢复已移除的旧导航页或复制难度列表。
- 提交前检查差异、资源引用和功能入口数量；保留他人未提交修改，公开反馈中附版本与最小复现步骤。

## 验证范围

纯视觉改动不新增或运行测试，默认不主动 analyze。数据一致性、账号和备份等高风险修改按需运行最小范围业务检查；只在编译报错或任务明确要求时分析相关文件。修改 Android Kotlin／Manifest 后必须构建 release APK，并核对合并清单。静态或桌面检查不能代替安卓真机结论。

临时渲染、截图与调查脚本放在忽略目录 `.dart_tool/` 或 `build/`；一次性排版探针和本地测试字体不参与客户端发布提交。
