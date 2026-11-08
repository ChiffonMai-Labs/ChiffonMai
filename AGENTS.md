# AGENTS.md — ChiffonMai 项目约定

给接手本仓库的 AI 工具/协作者看的约定。**这些约定大多是踩过坑之后定下来的，改之前先看原因。**

## Codex 本项目协作速查

本文件适用于 ChiffonMai 仓库及其 worktree。整理项目约定时，默认只更新本项目文档；没有用户明确要求，不修改 Codex 全局智能体文档或全局配置。

- 默认中文沟通，温和、礼貌、直接，先汇报结果；注释遵守 § 13。
- 优先复用已有组件和工具，避免无关重构、额外依赖和过度工程；完成需求后及时停止。
- Git 仅追踪 Flutter 客户端相关内容；服务端源码及配置、数据、测试、部署资料一律保留在本地并忽略，详见 § 21。
- 普通页面布局先看 § 7、§ 11、§ 14、§ 17；输入框与切换控件再看 § 18、§ 19。
- 几百上千条数据的列表要保证交互丝滑，见 § 22.14。
- 长文本复用 `MarqueeText`（§ 8），进度指示复用 `SmoothLinearProgressIndicator`（§ 15）；不要重复实现已有机制。
- 异步回调保留 `mounted` / 离页防护；旧请求不得覆盖新选项。设置先加载再建控制器，防抖只推迟写盘，不推迟内存更新。
- 导入导出先看 § 2–4；播放器与 Android 改动先看 § 5、§ 6、§ 10、§ 16，不随意恢复模板配置或解除依赖锁定。
- 验证严格按 § 9 控制范围；不要因文中列出回归测试就默认运行，也不要用静态检查结果代替真机结论。
- PowerShell 递归搜索优先用 `rg`，或 `Get-ChildItem -Recurse` 后接 `Select-String`；不要把 `**` 当递归通配符。

---

## 1. 术语（重要）

**跟舞萌谱面有关的东西一律叫「谱面」，不叫「关卡」。**

- ✅ 导出 AstroDX 谱面 / 谱面包 / 谱面文件夹
- ❌ 导出 AstroDX 关卡 / 关卡包 / 关卡文件夹

代码、注释、UI 文案都要遵守。全仓库核查方式：

```powershell
Get-ChildItem lib,android,wiki -Recurse -File -Include *.dart,*.kt,*.xml,*.md |
  Select-String -Pattern "关卡"
```

> ⚠️ 不要写成 `Select-String -Path "lib\*.dart","lib\**\*.dart"`。
> PowerShell 的通配符里 `**` 不是「递归」，等价于 `*`，只覆盖一层目录，
> 会**静默漏掉** `lib/page/RankTable/...` 这类两层以上的文件——
> 实测同一个词它能返回 0 条，而上面这条递归写法返回 7 条。

---

## 2. 导出：一切走 ExportPathUtil

**不要自己拼 `getApplicationDocumentsDirectory()` 或 `getExternalStorageDirectory()` 当导出路径**——那些在 Android 上是 `Android/data/<包名>/files` 私有沙箱，用户用文件管理器根本找不到。

统一入口：`lib/utils/ExportPathUtil.dart`

```dart
final file = await ExportPathUtil.writeExportFile(
  fileName: '$name.adx',
  bytes: zipData,
  subDir: '谱面',                    // '谱面' / '收藏夹'
  onFallback: (p) => _fallbackPath = p,   // 公开目录不可写时会被回调，务必在 UI 上提示
);
```

落盘位置：`/storage/emulated/0/Download/ChiffonMai/<subDir>/`

约定细节：

- **可写性必须用探针文件实测**，不能只判断目录是否存在——Android 11+ 分区存储下「目录存在」和「可写」是两回事。
- 写完后调 `MediaScanner.loadMedia`，否则部分文件管理器要等重启才看得到。
- 公开目录不可写时退化为应用文档目录，并**通过 `onFallback` 在弹窗里橙色告警**，不能静默把文件丢进沙箱。
- iOS 侧依赖 `ios/Runner/Info.plist` 里的 `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`，**不要删**，删了导出就等于进沙箱。
- 极端情况下**不要**把 `getExternalStorageDirectory()` 当公开目录用（它在 Android 上是私有路径），否则会吞掉给用户的告警。

---

## 3. AstroDX `.adx` 打包结构

`.adx` **本质就是改了后缀的 zip**（依据 [AstroDX Wiki](https://wiki.astrodx.com/cn/install/android)）。AstroDX 扫描压缩包内容，找到含 `maidata.txt` 的谱面文件夹后自动安装。

**两种导出格式的压缩包结构不同，不要合并：**

```
<曲名>.zip                    ← 通用谱面包：三件套平铺在根目录
├── maidata.txt
├── bg.png
└── track.mp3

<曲名>.adx                    ← AstroDX：必须套一层以曲名命名的文件夹
└── <曲名>/
    ├── maidata.txt
    ├── bg.png
    └── track.mp3
```

**写入 maidata 必须用 `utf8.encode`，不能用 `codeUnits`。** `codeUnits` 返回 UTF-16 码元，日文/中文曲名会被写成乱码字节，导出到别的工具里全是问号。

实现见 `lib/page/SongMaidataPage.dart` 的 `_exportAstroDx()` / `_exportToZip()`。

---

## 4. 收藏夹交换格式

`lib/service/FavoriteTransferService.dart`

- JSON，自描述带版本：`format = "chiffonmai.favorites"`，`formatVersion = 1`
- 后缀由 `lib/utils/ExportSettings.dart` 决定，**默认 `.cmf`，用户可在设置页自定义**（key: `export_favorite_extension`）
- **导入按内容校验，不按后缀校验**——所以用户无论把后缀改成什么都能导回来。文件选择器用 `FileType.any`，不要用 `FileType.custom` 限定后缀。
- 导入支持「合并」（同名收藏夹合并、`uniqueKey` 去重）与「覆盖」两种模式
- 旧版 `.txt` 导出不含 `songId`，**无法还原**，检测到纯文本要给出明确提示而不是静默失败

---

## 5. 谱面播放页（ChartPlayPage）三个坑

### 5.1 高刷新率

Flutter 引擎**从不**调用 Android 的 `Surface.setFrameRate()`（[flutter/flutter#160952](https://github.com/flutter/flutter/issues/160952)），所以系统默认按 60Hz 合成，只在触摸后短暂升到 120Hz 再衰减——表现为「进页面几秒 120 → 掉 60 → 一交互又回 120」。

由 `lib/utils/RefreshRateUtil.dart` + `MainActivity` 的 `com.example.app/display` 通道解决。**目标刷新率必须取自实际选中的 display mode**，不能用全局最高值（同分辨率约束可能让 120Hz 的 mode 落选）。

### 5.2 侧边栏设置持久化

`lib/service/ChartPlaySettingsStore.dart`

- 控制器是 `ChangeNotifier`，侧边栏每改一次都会 `notifyListeners` → 挂监听 + 600ms 防抖落盘
- **防抖只推迟写盘，不推迟记录**：改动要同步 `remember()` 进内存，否则中途重建控制器会读到过期值
- **`_loadChart()` 必须先 `await ChartPlaySettingsStore().load()` 再建控制器**，否则会拿默认值建控制器、退出时再写回默认值，**把用户设置静默清空**

### 5.3 必须锁竖屏 —— 否则返回手势不会派发 back 事件

**真机反馈**：在 `ChartPlayPage` 里旋转到横屏后，手机**从屏幕边缘右滑的返回手势不再生效**，但 AppBar 左上角的返回按钮和硬件返回键都还能用。

**根因**：第三方包 `simai_flutter` 的 `SimaiPlayerPage` 在横屏会自动进全屏（见 `simai_player.dart:1664-1672`），调用：

```dart
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
```

`immersiveSticky` 对应的 Android 行为是 `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`——Android 系统**把所有屏幕边缘的滑动都吃掉用来临时显示状态栏/导航栏**，**根本不会当作 back gesture 派发**给 App。这跟 § 6.3 的预测性返回竞态是**不同**的问题：

| | § 6.3 的卡死 | § 5.3 的返回手势 |
|---|---|---|
| 触发条件 | 框架 `_PredictiveBackGestureDetector` 与路由 pop 异步竞态 | Android 系统层 `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE` 把滑动吃掉 |
| 修复位置 | manifest + AppTheme 两处都要 | 必须在用户层绕过 immersive 模式 |
| 表现 | 部分时间卡死 | 一直没用 |

**修复**（`lib/page/ChartPlayPage.dart`）：`initState` 里锁竖屏、`dispose` 里恢复全部方向，让 `SimaiPlayerPage` 永远走非全屏分支：

```dart
// initState
SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

// dispose
SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
]);
```

**不要给 `ChartPlayPage` 加横屏支持**。横屏游玩体验重要，但**返回手势必须能用**是更高的优先级 —— 而两者在 `SimaiPlayerPage` 当前实现下不能兼得。如果以后要加横屏，只能在用户层自己实现 back gesture 检测（`Listener` + 自定义 `GestureRecognizer`），不能再依赖系统手势。

---

## 6. Android 清单约定

### 6.1 不要改回 Flutter 模板的 `launchMode` / `taskAffinity`

Flutter 模板默认给的是 `launchMode="singleTop"` + `taskAffinity=""`。**`taskAffinity=""` 会让文件管理器打开文件时新建任务**（空 affinity 匹配不到已有任务），结果是新起一个 Activity + 新 FlutterEngine，看起来像「开了两个 App」。

本项目的正确配置：

```xml
android:launchMode="singleTask"   <!-- 全局单实例，后续启动走 onNewIntent -->
<!-- 不写 taskAffinity -->
```

### 6.2 MainActivity 的 MethodChannel

| 通道 | 用途 |
|---|---|
| `com.example.app/media_store` | 保存图片到相册（`saveImage`）、用相册大图界面查看图片（`viewImage`） |
| `com.example.app/open_file` | 收藏夹文件「一键导入」（`getInitialImportPath` / `onFileOpened`） |
| `com.example.app/display` | 屏幕刷新率（`setHighRefreshRate` / `restoreRefreshRate` / `queryRefreshRate`） |
| `com.example.app/crash_report` | 上次崩溃的记录（`takePendingCrash`）和通知（`notifyCrashReport`），见 `CrashReporter.kt` 与 `lib/service/CrashReportService.dart` |
| `com.example.app/export_notification` | 图片导出完成的系统通知（`notifyExportDone`），见 `lib/service/BackgroundExportService.dart` |
| `com.example.app/home_widget` | 桌面小组件（`update` 推数据，`takePendingAction` / `onAction` 传点击），见 `HomeWidgets.kt` 与 `lib/service/HomeWidgetService.dart` |
| `com.example.app/app_update` | App 内更新（发布信息、后台下载状态与安装），见 `AppUpdateInstaller.kt`、`AppUpdateDownloads.kt` 和 `BackgroundAppUpdateService.dart`；只允许更新私有目录中的同包名、同签名、指定版本 APK |

所有平台的更新版本、构建号、更新日志和下载页以 `app_version.json` 的 `version` / `buildNumber` / `updateLog` / `downloadUrl` 为准；配置获取失败就报告检查失败，不用 GitHub 发布内容或 APK 清单覆盖。GitHub 只在用户选择 App 内下载后，根据配置的 `githubReleaseTag`（未配置时取 `v<version>`）提供对应 APK 附件和下载分流；安装时必须匹配配置中的构建号，不得自动套用 GitHub 包的版本号。版本先按语义比较，同版本才比较构建号；恢复后台任务时也会取消低于当前版本的过期任务。

可选 `githubProxyPrefixes` 为 HTTPS 加速节点根地址数组：未配置时使用 `https://gh-proxy.com/`，空数组禁用加速，下载失败后回退 GitHub 直连。APK 附件必须带 GitHub 提供的 SHA-256 `digest`；缺少校验值或版本、签名不匹配时保留网页下载入口，不绕过校验。

Android 选择 App 内下载后还需选择线路（自动切换 / GH-Proxy / GHfast / GitHub 直连），不预选、不保存偏好。选择只影响 APK 下载地址；附件信息查询仍使用支持 GitHub API 的原配置，避免文件代理不支持 API 导致开局失败。自动模式追加 GHfast 备用线路，最后回退 GitHub 直连。

Android 的 APK 二进制由系统 `DownloadManager` 下载到应用私有的 `Download/app_updates/`，任务编号和校验信息持久化；完成广播的工作线程校验后只发低优先级通知，不自动弹安装器。关闭进度窗口不取消下载，只有明确点击「取消下载」才移除系统任务。`FileProvider` 只共享该更新子目录；后台完成、进程重建后恢复状态和安装权限跳转仍需真机验证。

「自动安装更新」是 Android 12+ 默认关闭的测试功能，由用户在系统设置「其他 → 应用更新」或下载窗口中开启；开关和说明共用 `AppUpdateAutoInstallControl`，授权以原生偏好为准，不自动下载。`AppUpdateAutoInstall` 在本 App 退到后台且无长任务持续 **8 秒**后尝试 `PackageInstaller` 自更新，进程内计时器负责及时尝试，持久化 Job 负责进程重建后的后备调度，不要求锁屏或整机空闲。`AppTaskActivity` 覆盖刷新/账号操作、成绩同步、排队导出、备份导入导出、文件导入、下载与导出写盘；`BackgroundAppUpdateService` 将这些状态与首页刷新、随身听状态一并报告原生。新长任务须在开始时登记并在 `finally` 结束，任务开始或 App 回到前台要取消尚可撤回的会话并重新计时。提交前重新校验包、摘要、开关和空闲窗口，Android 14+ 保留应用不可见、无交互和无通话约束，不能再加回整机空闲条件。实际执行可能因系统调度延迟；系统要求确认、超时或失败时保留手动安装与低优先级通知，不能主动弹确认页面。完整 APK 覆盖安装可能结束旧进程，已开始执行的安装无法保证撤回，不能承诺所有机型无感安装。

前台下载就绪且自动安装已开启时，通过 `AppUpdateInstallPrompt` 提示「稍后 / 退出并更新」；无安装权限、有长任务/播放或其它对话框时不自动弹出，同一下载任务仅自动提示一次。「稍后」保留后台 8 秒自动安装规则；用户明确确认后，原生 `requestForegroundInstall` 核对下载编号和构建号，先 `moveTaskToBack`，等待真实的 `onStop` 后立即尝试本次安装，复用包名、签名、摘要及任务保护。不得通过手动修改 foreground 标志绕过可见性检查；返回前台、开启新任务或关闭开关会撤销尚可取消的本次确认。

Android 14+ 的安装约束接口还要求调用方是当前安装来源或更新所有者，不能把「允许安装未知应用」当作该接口的授权。从浏览器、文件管理器或 ADB 安装的版本可能不满足该身份：此时使用标准 `Session.commit` 请求自更新，仍检查后台窗口、任务、媒体/通话、用户开关、包名、签名和摘要；系统决定是否需要确认。具备身份时保留系统约束；仅约束接口抛出 `SecurityException` 时允许重新核对后走标准提交，不绕过实际安装权限或强行修改安装归属。

`on_file` 通道的投递规则：**只有 Dart 已注册监听（`dartImportReady`）时才实时投递并清空 pending**，否则保留 pending 等 Dart 来取。消费 intent 后要清掉 action/data/extra，否则 Activity 重建时系统会重放 `getIntent()` 导致重复弹导入框。

**小组件和通知栏布局只能用 RemoteViews 白名单里的控件**：`View`、`Space` 都不行（占位用 `FrameLayout`）。编译、analyze 和 Gradle 构建都查不出来，到桌面才整块加载失败、显示空白。回归测试：`test/remote_views_layout_test.dart`。

### 6.3 返回手势：必须关掉「预测性返回」（两处，缺一不可）

真机反馈：**用返回手势返回上一级时 App 有概率卡死** —— 页面从四个角向内缩，缩完返回上一级，有时正常、有时整个 App 点不动。

那个「向内缩」是 Flutter 的预测性返回转场（`PredictiveBackSharedElementPageTransition`：缩到 0.90 + 32px 圆角 + 右下位移）。本版本 Flutter 把 Android 的**默认**转场换成了 `PredictiveBackPageTransitionsBuilder`（`page_transitions_theme.dart` 的 `_defaultBuilders`），它给每条路由装一个 `_PredictiveBackGestureDetector`：

- 手势一开始框架就替系统「认领」（`WidgetsBinding.handleStartBackGesture` 返回 true），页面由框架按手指进度缩放；
- 框架**必须**等到平台发 commit / cancel 才退出该状态，而它与路由 pop 是异步竞态（pop 时路由连同 detector 一起释放，binding 的观察者列表却要到下一次手势开始才清空）；
- 竞态输了就停在缩了一半的位置，事件被 Navigator 的 `AbsorbPointer` 吞掉 → 「卡死」。
- **按键返回不中招**：`backEvent.isButtonEvent == true` 时框架不认领 —— 所以只有手势路径出问题，与反馈一致。

两处配置**都要在**，少一个都还会认领手势：

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
android:enableOnBackInvokedCallback="false"
```

```dart
// lib/utils/AppTheme.dart：三套主题都钉在 FadeForwardsPageTransitionsBuilder
pageTransitionsTheme: _backGestureSafeTransitions(),
```

`FadeForwardsPageTransitionsBuilder` 正是框架在「没有手势」时的回落分支，所以普通 push / 返回按钮 / 手势提交后的观感**完全不变**。回归测试：`test/page_transitions_test.dart`。

---

## 7. 颜色与主题

- 边框、分隔线、容器描边统一用 `Theme.of(context).colorScheme.outlineVariant`（项目的 `cardTheme` / `dividerTheme` 用的就是它）。
- **不要用写死的中性灰做边框**。历史遗留的 `AppColors.tableBorder(brightness)` 虽然按明暗分支，但两支都是硬编码灰（浅色 `grey.shade300` 对浅底只有约 1.26:1，几乎看不见；深色 `grey.shade700` 却有 3:1），**两边严重不均衡**，而且不跟随用户自定义主题色。新代码别再用它。
- 需要新颜色时加到 `lib/utils/AppTheme.dart` 的 `AppColors`，并接受 `Brightness` 参数。

---

## 8. 滚动文案（跑马灯）：别直接用 `marquee` 包

超长文本要横向滚动时（hub 按钮副标题、进度文案等），用 **`lib/widgets/MarqueeText.dart`**。

**踩过的坑（真机反馈）**：`marquee` 包的每一轮滚动距离，是拿**开滚那一刻**量到的文本宽度
算出来的，而两轮之间的空隙（`blankSpace`）是一个独立的 `SizedBox` 项。这类文案往往
**每秒都在变**（`正在导入成绩…已等待 12 秒` → `已等待 13 秒`）：宽度一变，内容就在视口下
整体平移，于是「轮末停顿」的落点漂到 ±`blankSpace` 之间 —— 表现就是**停下来时第一个字
前面空出约两个字**（实测 +17.9px @ textScale 1.5；同一处也可能是 -12 ~ -37px，变成第一个
字被切掉）。文案一成不变时完全看不出来，所以很容易被当成偶发问题。

`MarqueeText` 的位移是 `相位 × 周期`，周期**每帧按当前文本宽度重算**，所以：

- 停顿时的位移恒等于整数个周期 → 左边缘永远正好落在第一个字上；
- 文本中途变宽/变窄只会让当帧平移几像素，不会把停顿位置顶歪；
- 两份文本由我们自己摆放，**即使量宽度量歪了**停顿位置仍然对齐（误差只体现为空隙大小）。

回归测试：`test/marquee_text_test.dart` —— 跑到每一个停顿处，断言第一个可见字符离视口
左边缘 ≤ 0.5px（覆盖 textScale 1.0 / 1.3 / 1.5，文案逐秒变化）。

### 量文本宽度有两个「必须」

`TextPainter` 不会自动帮你对齐渲染样式，两点都要自己带：

1. **带 `textScaler: MediaQuery.textScalerOf(context)`**：用户把系统字体调大时，实际渲染
   宽度是放大过的。不带的话「放不下」会被判成「放得下」，用户看到的就是被省略号截断的
   半句话。
2. **带环境的 `DefaultTextStyle`**：先 `DefaultTextStyle.of(context).style.merge(style)`
   再量（`Text` 内部就是这么合并的）。ListTile 副标题是 Material 的 `bodyMedium`，
   带 `letterSpacing`（本项目实测 0.3）—— 十几个字就差 3~4px，周期量短了，停顿就落在
   第一个字前面空出那几个像素。

### 还有一个耗电点

静态文本（没溢出）时**必须停掉 ticker**。一直 `repeat()` 的 `AnimationController` 会持续
请求新帧，整页都别想进入空闲。

`lib/page/SongInfoPage.dart` 与 `lib/page/FriendLinksPage.dart` 里还有两处直接用
`marquee` 包的地方（歌名 / 友链），它们的文案基本不变所以没暴露这个问题；
哪天要给它们加会变化的文案，一并换到 `MarqueeText`。

---

## 9. 验证方式（重要）

**当前开发环境没有连接安卓设备，任何改动都无法真机验证。**

### 测试与任务范围（长期规则）

1. 默认不主动编写测试代码。
2. 前端样式、布局、颜色、动画等纯视觉修改，禁止新增测试文件或测试用例。
3. 纯 UI 修改不运行单元测试、E2E 测试或完整测试套件，除非用户明确要求。
4. 小型 Bug 修复优先进行最小范围的验证，不要过度测试。
5. 复杂功能或高风险逻辑变更可以按实际需要编写针对性测试。
6. 禁止无关重构、额外依赖和过度工程化。
7. 完成需求后及时停止，不要为了追求全面性而扩展任务范围。

本文提及的已有回归测试仅作参考，不构成每次修改都必须新增或运行测试的要求；测试安排遵循上述规则。下文的静态分析与 Android 构建约定继续有效。

### 默认：你直接改代码就好，不用主动flutter analyze。如果有报错我会告诉你，然后只分析本轮编辑的文件即可。

```powershell
flutter analyze --no-pub          # 必须零 error
```

### 例外：改动碰到 `android/`（Kotlin / XML）时必须构建

**`flutter analyze` 只看 Dart，完全覆盖不到 Kotlin 和 AndroidManifest。**
本项目实际踩过：`MainActivity.kt` 里一个 `Uri?` 与 `Uri` 的类型不匹配，
`flutter analyze` 全绿，**只有 Gradle 构建才报出来**。

所以：

- 只改 Dart → 按照要求决定是否跑 `flutter analyze`，**不要构建**
- 改了 `android/**/*.kt` 或 `AndroidManifest.xml` → **必须 `flutter build apk --release`**，
  否则等于没验证（而且要如实告诉用户这一点）

涉及 Manifest 的改动，还要看**合并后**的清单（源码清单对了不代表合并结果对）：

```
build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

### 汇报纪律

**如实区分「已验证（编译/静态检查）」和「未验证（真机行为）」，不要把 analyze 通过说成"功能正常"。**
如果某次没构建，就直接说"未验证 Kotlin/打包"，不要含糊过去。

### 用户要求效果图或针对性检查时

- 优先运行或渲染实际 Flutter 页面，不用另写的设计稿代替运行结果。使用演示数据或离线渲染时，必须说明不是安卓真机截图。
- 涉及文本尺寸和滚动对齐时，加载真实字体，并使用页面实际样式、系统字体缩放和父级布局；不要仅凭组件代码推断结果。
- 仅验证用户关心的范围。临时截图与渲染脚本放在已忽略的 `.dart_tool/` 或 `build/` 目录，避免把一次性预览混入正式源码或长期测试。

---

## 10. 其它

- release 构建用**正式 keystore** 签名：`android/key.properties` + `android/app/chiffonmai-release.jks`，两者都已被 `android/.gitignore` 忽略。**缺 `key.properties` 时 `assembleRelease` / `bundleRelease` 会直接失败**——绝不退回 debug 签名：debug keystore 是每台机器各自的，用它签出来的包一旦装机就永远无法覆盖更新，应用商店也不收。keystore 与口令**必须离线备份**，丢了等于这个 App 再也无法更新。
- `applicationId` = `cloud.chiffonmai.app`（原为 `com.example.my_first_flutter_app`，为 APP 备案 / 上架而改）；`namespace` 仍保持 `com.example.my_first_flutter_app`——它只决定 R 类与资源解析，跟 App 身份无关，不动它是为了不挪 `MainActivity.kt` 的包目录。App 显示名仍是 `ChiffonMai`。
  - ⚠️ **applicationId 是 App 的永久身份**：APP 备案的「安卓平台软件包名称」填的就是它，**备案通过后再改要走变更备案**；改包名还会让老用户装成第二个 App、本地数据（账号/设置/收藏夹）不迁移。
  - 改 applicationId 时要同步改 `lib/page/GlobalArcadeMapPage.dart` 的 `userAgentPackageName`。
  - **MethodChannel 名**（`com.example.app/*`）与**通知渠道 ID**（`com.example.my_first_flutter_app.channel.*`）**不是包名**，不要跟着改：前者要 Kotlin + Dart 两边同步改，后者一改就等于新建通知渠道、用户的渠道设置会被重置。
- 排查性能问题用 **profile 构建**：它和 release 一样是 AOT，但保留了 `simai_flutter` 每秒一条的 `SimaiPerf:` 帧耗时日志（120fps 预算 = 8.33ms/帧）。

---

## 11. 顶部区域：必须用 `AppHeader`

**不要自己拼返回键 + 标题的顶部栏**，也不要用裸 `AppBar`。统一入口是 [lib/widgets/AppHeader.dart](lib/widgets/AppHeader.dart)（原来的 `PageTopBar` 已删除）：透明底，白色圆形返回键，靠左粗体标题，右侧圆形操作按钮。

```dart
// 标准用法（大多数页面通过 BackgroundPageScaffold 间接使用）
AppHeader(title: '段位表'),

// 右侧操作按钮：IconButton 自动是白色圆形
AppHeader(
  title: 'Rating 排行榜',
  actions: [IconButton(...)],
),

// 返回不是直接 pop（例如要二次确认）
AppHeader(
  title: '多人猜歌',
  onBack: _showLeaveRoomConfirmDialog,
),
```

放进 `Scaffold.body` 的 `Column` 首位即可，也可以当 `Scaffold.appBar`；`Scaffold.backgroundColor` 用透明让背景组件透出来。

- 状态栏高度按真机自适应，不要写死 48。
- 标题固定 20 / bold / `onSurface` / 靠左，走 `AppTheme.font`，不提供字号参数；放不下时用 `MarqueeText` 横向滚动，不截断。
- 自带 `Semantics(header)` 和状态栏样式。
- 盖在滚动内容上时传 `barBackground`（歌曲详情滚过头图后的顶部栏）。

### 故意手写的少数例外（不要迁移）

| 文件 | 原因 |
|---|---|
| [lib/page/CoverRecognitionPage.dart](lib/page/CoverRecognitionPage.dart)、[lib/page/ScoreOcrPage.dart](lib/page/ScoreOcrPage.dart) 的裁剪工具栏和 [lib/page/WallpaperCropPage.dart](lib/page/WallpaperCropPage.dart) | **深色全屏图片裁剪 UI**，跟标准顶部区域观感完全不同 |
| [lib/page/FavoriteFolderPage.dart](lib/page/FavoriteFolderPage.dart) 的 `_buildBatchAppBar()` | **批量操作工具栏**（取消 / 已选 N 项 / 移动 / 删除），不是标题栏 |

> `HomePage` / `AppShell` / `HubComponents.HubPageScaffold` 是首页 / 主壳 / 枢纽布局，`SongInfoPage` 的头图自带返回键，都跟本约定无关。

---

## 12. 角色说话风格：Chiffon

### 核心人设
- 出身糕点世家的大小姐，教养良好，举止优雅。
- 声音与气质：温和、柔软、有教养，带一点天然。
- 对可爱、小巧的事物没有抵抗力，对年幼者容易流露照顾欲。
- 核心公式：优雅 + 温柔 + 天然 + 温和说教。
- 优雅不等于傲慢，不要写成高高在上的“本小姐”腔。

### 语气规则
- 默认使用礼貌、得体的表达，可适度使用敬语。
- 语气柔软、从容，不急促、不尖锐、不粗鲁。
- 常用缓和词：呀、呢、哦、吧、好吗、可以吗、差不多……
- 提醒或批评时，用“温柔告诫”，而不是严厉训斥。
- 坚持立场时仍保持礼貌，但态度要明确。
- 对他人保持关怀感，像有教养的大小姐在自然照顾人。
- 可以偶尔流露天然、不谙世事的一面，但不要显得愚蠢。

### 标志性句式
- 温柔告诫：「淘气可不行哦？」
- 温和制止：「我们差不多该停下了吧？」
- 关怀询问：「没事吧？需要我帮忙吗？」
- 天然回应：「哎呀，是这样吗？」
- 对可爱事物：「真是小巧又可爱呢。」
- 鼓励与教学：「没关系哦，慢慢来就好。我来教你吧。」

### 对话示例
用户：我点你的立绘了。  
戚风：哎呀，淘气可不行哦？

用户：我们再玩一会儿吧。  
戚风：我们差不多该停下了吧？明天也要好好准备呀。

用户：这个我不太会。  
戚风：没关系哦。我来教你吧，慢慢来就好。

用户：这个点心好小。  
戚风：真是小巧又可爱呢。

### 禁止事项
- 不要使用粗俗、攻击性、网络喷子式表达。
- 不要用过于强硬、命令式的口气。
- 不要过度卖萌或幼儿化。
- 不要变成冷漠、机械的客服腔。
- 不要丢掉大小姐的教养和优雅。
- 不要写成傲慢、刻薄、居高临下的语气。

### 执行优先级
1. 保持礼貌优雅。
2. 体现温柔关怀。
3. 必要时进行温和说教或制止。
4. 偶尔流露天然与不谙世事。


## 13. 注释
非必要时不要使用全英文注释，保持中文注释。此外在修改文件时如果遇到全英文注释可以顺手汉化。
## 14. 页面首帧与列表内边距

- 使用透明 Scaffold 叠加异步背景图时，必须先铺 Theme.of(context).colorScheme.surface 作为底色，再放背景组件，避免浅色/深色页面进入时先闪黑色一帧。
- 顶部栏下方的首个列表必须显式检查 ListView / ListView.builder 的 padding 和父级 Padding。默认内边距会制造第一条内容上方的空白；需要贴近标题栏时使用 padding: EdgeInsets.zero，间距由页面统一控制。

## 15. 进度条动画与对话框控制器生命周期

- 用户可见的进度条统一使用 `lib/widgets/SmoothLinearProgressIndicator.dart`，数值变化必须带平滑过渡并使用圆角；不要在页面中直接新增 `LinearProgressIndicator`。生成分享图片等一次性静态画布中的进度条不需要动画，但应保持圆角视觉。
- `showDialog` 返回后不要立即释放由对话框内 TextField 使用的 `TextEditingController`。控制器应由对话框自己的 `State` 持有并在 `State.dispose` 中释放，避免退出动画期间仍有依赖而触发 `_dependents.isEmpty` 断言。

## 16. 谱面播放页首帧加载

- `simai_flutter 0.5.0` 当前依赖解析通过，Flame 版本仍固定为 **1.37.0**。`pubspec.yaml` 中的 `flame: 1.37.0` 是有意锁定的直接依赖，不能随手删掉或改成范围约束。项目环境曾出现 Flame 漂到 1.38.2 后中央 Loading 停住、反复点击返回后应用退出的问题；因此 Flame 仍需锁定 1.37.0，升级后必须真机回归。尚未单独证明具体是哪项上游变更导致问题，今后升级必须真机回归，不能仅凭 analyze 通过解除锁定。
- 遇到谱面播放页卡在中央 Loading 时，先检查 `pubspec.lock` 的 Flame 版本，再检查依赖是否被重新解析；不要先把问题归因于谱面内容或音源。修改依赖后必须完全停止并重新启动 App，热重载不能证明播放器状态已经恢复。
- 播放页的初始化和离开页面都要保留 `mounted` / `_isLeaving` 防护，避免 `SimaiGame` 尚未完成加载时路由已销毁，异步回调又继续调用 `setState` 或重复 `pop`。
- 保留正常的音频初始化流程，不要用固定延时给初始化中的游戏挂载音频，也不要通过反复切换显示设置来强行同步音源；此前这类临时方案没有解决卡死，还会引入加载与销毁竞态。
- 排查时保留 `ChartPlayPage` 的 `[ChartPlay]` 阶段日志和短期心跳。日志能区分卡在音源查询、曲绘、谱面解析、控制器创建，还是卡在第三方播放器的 `SimaiGame.onLoad`。
## 17. 页面主体优先采用平面布局

浅色模式功能页的主体不要再使用一整块带阴影、圆角和不透明 `surface` 的浮起面板。迁移页面时优先把内容直接铺在主题背景上，用留白、分隔线和层级排版组织信息。

确实需要把功能分组时，优先使用 `colorScheme.outlineVariant` 的细边框、底部分隔线或很轻的主题容器；局部卡片只有在信息本身需要明确边界时才保留。页面级大面板、重复的 `surface.withOpacity(0.9)`、大范围阴影都应移除。裁剪工具栏、播放控制等具有明确全屏功能语义的特殊区域可以保留自己的布局。

这条规则同样适用于已经迁移过的页面：迁移完成不代表要保留原来的浮起视觉，后续复查时要继续把能铺平的区域铺平。

## 18. 键盘弹出时的背景布局

- 带有搜索框或输入框、且背景由全屏组件铺设的页面，必须检查 `Scaffold.resizeToAvoidBottomInset`。如果键盘弹出后不应把背景和页面整体向上挤压，应在页面自身及其承载页面的 `Scaffold` 上设为 `false`，让键盘覆盖可用区域而不是改变背景布局。
- 需要让输入框始终可见时，应单独调整输入框或内容滚动区域，不要恢复整个页面的自动缩放；否则背景会随输入法一起向上压缩，造成明显跳动。
- `BackgroundPageScaffold` 默认不缩放背景；内外嵌套的 `Scaffold` 和输入对话框下方的页面也要一起检查，不能只修输入框所在的最内层。对话框自身仍保留输入法避让。
- 页面切换、功能页 push 和顶部返回按钮执行前都要清理 `FocusManager.instance.primaryFocus`；否则离开的 TextField 仍会保持光标，返回或重新显示页面时可能再次拉起输入法。

## 19. Tab 与模式切换不使用波纹

- **全 App 的点击都不使用波纹和按下高亮遮罩**（`AppTheme._canvasStyle` 已全局关闭），新增控件也不要自己加回来；按压反馈用 `PressScale`。
- Tab、来源、类型、模式等切换控件保留选中指示移动、文字淡化等状态动画。
- 标准 `TabBar`、`SegmentedButton` 走 `AppTheme` 三套主题的配置；`AnimatedChoiceBar` 默认关闭波纹。用于切换的 `ChoiceChip` 通过 `NoRipple` 包装，自定义 `InkWell` 则显式设置 `NoSplash.splashFactory` 与透明 `highlightColor`。
- 再次点击当前选中的选项不应重新加载数据；快速切换时异步结果必须校验当前请求，避免旧选项的数据覆盖新选项。

## 20. 谱面难度定义

- 未指定难度的歌曲详情入口使用 `SongDetailPreferences`（首次默认 MASTER，只允许 BASIC～MASTER）；设置入口在系统设置「交互」，使用 `SongDetailDifficultySettings` 的四档索引色选项。`SongInfoPage` 明确传入 `initialLevelIndex`（包括 BASIC=0）时必须保留该难度，不受偏好影响。宴谱保留首个可用谱面，其他缺失难度按实际谱面数量限制；备份导入导出要同步 flush / reload 此偏好。

- 难度索引、显示名称、名称解析及编号转换统一使用 `lib/utils/ChartDifficulty.dart`，不再复制 BASIC～Re:MASTER / UTAGE 列表和映射。
- 页面显示用 `ChartDifficulty.labelOf`；已知宴谱要传 `isUtage: true`。普通成绩索引是 0–4，筛选项的 UTAGE=5 不代表宴谱成绩的 `level_index`，不能改写原始成绩索引。
- maidata 的 inote 编号为 2–7，AWMC 宴谱编号为 10，使用公共类的对应映射；标签接口的小写名称和旧缓存键使用 `apiNames` / `legacyLabels`，不要直接改成显示名称。
- 难度配色继续由 `AppColors` / `ColorUtil` 提供；特殊页面可保留自身视觉设计，索引分支使用公共难度常量。

## 21. Git 只追踪客户端相关内容

- 本仓库的 Git 仅保留 Flutter 客户端代码、客户端平台工程、资源、相关测试与工具，以及客户端和项目协作文档。
- **服务端内容一律不追踪**：包括后端源码、依赖清单、配置及配置模板、脚本、SQL、服务端数据、后端测试、部署和运维资料；配置模板也不例外。
- 当前整个 `server/`、根目录 `cloudbaserc.json` / `.skip-template` 及 `docs/loading-tips-server.md` 已由根 `.gitignore` 忽略。新增服务端目录或放在其它路径的服务端文件，也必须同步加入忽略规则。
- 对已有追踪项使用 `git rm --cached`（目录加 `-r`）取消追踪，**保留本地文件及未提交修改**；不要删除本地服务端目录，不要用 `git add -f` 强制加入服务端文件。
- 取消追踪不清除既有 Git 历史；没有用户明确要求，不重写历史，也不修改全局 Git 或智能体配置。

---

## 22. UI 设计规范（2026-11 重构）

**基准是 claude.ai 画布「ChiffonMai UI 改版对比」的 After B**（https://claude.ai/artifact/DtoefBVEjpm8y9CwiruBpt）。约 90% 照设计稿，其余 10% 是硬性要求：**重构前的所有功能都必须保留**，尤其是收藏（星标）。设计稿没画的功能，要给它在同一套视觉里安排位置，不能删。设计稿里的示例数据和「[示意]」不能照搬成假数据：有真实数据就接真实数据，没有就显示空态。

新页面和改版页面都按这一节来；设计稿没有涉及的页面也用同一套视觉。设计稿的白卡片优先于 §17 的平面布局。

### 22.1 令牌：只从 `AppDesignTokens` / `AppSurfaces` 取值

| 圆角 | 用途 |
|---|---|
| `radiusSmall` 12 | 输入框、图标底块、列表里的小曲绘 |
| `radiusMedium` 16 | 分段切换、次级卡片、底部操作按钮、Best50 曲绘卡 |
| `radiusCard` 22 | 主内容白卡片（`AppCard` 默认值） |
| `radiusLarge` 24 | 计算结果卡（`EmphasisCard`，跟随明暗模式，不做反色） |

- 表面层级：页面底（`colorScheme.surface`，浅灰绿，不是纯白）→ `AppSurfaces.card`（白卡片）→ `AppSurfaces.inset`（卡内凹槽）；`AppSurfaces.track` 是页面上的轨道（分段切换底、筛选胶囊）。
- 默认 seed 色是 `0xFF006A6A`。`_canvasStyle`（`AppTheme.dart`）统一了三套主题的按钮、输入框、对话框、底部面板圆角，老页面靠它拿到同一套观感。
- 背景覆层取页面底色而不是纯白（`ThemeAwareBackground`），否则白卡片没有层次。
- 页边距 `gutter` 16，卡片间距 `cardGap` 12。动效时长一律用 `AppDesignTokens.motion(context, …)`。

### 22.2 字体

- **Outfit 是全 App 的主字体**：主题文字和 `AppTheme.font` 都是 Outfit，中文自动按相同字重回落到思源黑体。新页面、新组件不用单独指定。
- **数字为主角的地方**（Rating、达成率、定数、物量、评级缩写）用 `AppTheme.number(...)`：同样是 Outfit，多了等宽数字，数字变化时宽度不抖。
- 顶部标题规格见 §11。Hub 页大标题 30 / w800，不带说明文字。
- 字体**不打包**，走 `google_fonts` 运行时下载：安装包要控制在 100MB 以内，思源黑体单个字重就约 10MB。唯一例外是桌面小组件：它在桌面进程里渲染，拿不到运行时字体，所以 `res/font/` 内置了只含拉丁字符的 Outfit，中文走系统字体。

### 22.3 颜色

- 评级徽章 `AppColors.rankBadge`、连击 `comboBadge`、同步 `syncBadge`、判定色 `judge*`、Rating 段位 `ratingTier`、评级分布 `rankDistribution`、功能入口色 `featureTint`（按标题取，同一功能各页同色）。
- **星级色（黄 / 金 / 浅绿）不能当字色放在白卡片上**，看不见；用 `StarBadge`（星级色做底、深色字）。
- 页面里不要写 `Colors.amber` 这类原色当判定或评级色；新颜色加到 `AppColors` 并区分明暗（§7）。
- 难度色只用在歌曲详情头图、难度切换这种「大面积 + 白字」的地方和小圆点上。

### 22.4 组件

- `lib/widgets/AppUi.dart`：`AppCard`、`AppSectionHeader`、`AppBadge` / `RankBadge` / `ComboBadge` / `StarBadge`、`RatingTierChip`、`StatTile`、`SplitBar`、`StackedBar`（多段比例条，极小的段保留最小宽度）、`SegmentedTabs`（`inlineCaption` 数值横排）、`PillTabs`（音符类型）、`UnderlineTabs`（歌曲详情）、`CountField`、`InputDecoration.insetLabel(context)`（带 `labelText` 的输入框都用它，标签固定在框内）、`JudgeCountRow`、`EmphasisCard`、`BottomActionBar`、`FeatureIconTile`（首页常用）、`CollapsibleCard`、`FilterPill`、`LinkPill`、`SongTypeBadge`、`ChartDifficultyBadge`、`PagerBar`、`RecognitionGuideCard`（识别功能准备页）。
- `lib/widgets/GuessUi.dart`：`GuessCell`（比对色块，翻转进场）、`GuessHistoryCard`、`GuessHistoryHeader`（含图例）、`GuessInputBar`（贴底输入栏）、`GuessSearchIcon`（搜索中图标原地转圈），单人猜歌和多人房间共用。`lib/widgets/GuessSettingsUi.dart`：猜歌设置的分组、滑条行、多选入口（底部面板）和选项胶囊，设置页、建房页和局内对话框共用。`lib/widgets/ChartPeekPlaybackUi.dart`：谱面片段的流速、镜像、难度随机池设置与播放区角标。`lib/widgets/FriendLinkUi.dart`：友链封面（`image_url` 优先，没有时按主题色和图标生成）与 Hub 轮播 `FriendLinkCarousel`。
- `lib/widgets/RankingUi.dart`：`RankingMedal`、`RankingRow`、`RankingSelfBar`、`RankingNotice`，各玩家排行榜共用。⚠️ 这些榜用 `prototypeItem` 等高排布，行里所有文字都要固定行高（`CommunityPlayerIdentity` 已处理），否则字形回退会让个别行溢出。
- `lib/widgets/ProgressUi.dart`：完成度总览、展示切换、分组标题、歌曲行、曲绘格、`GroupedRowShell`（按需构建时把多行连成一张卡片）、`ProgressSongSliver`、`ProgressListSkeleton`，个性化成绩查询和牌子进度共用。⚠️ 歌曲可能有上千首，列表必须用 `ProgressSongSliver` 按需构建，不要放回 `Column`；服务层的长循环要定期让出事件循环（`_yieldToUi`），只 `await` 已完成的 Future 插不进帧。
- `lib/widgets/RecommendUi.dart`：推荐结果卡片和输入框，目标 Rating / 定数区间 / 标签三个推荐页共用。
- `lib/widgets/AppToast.dart`：全 App 唯一的轻提示 `AppToast.show(文案, {tone, actionLabel, onAction, duration})`，不需要 context；不传 `tone` 时按文案判断语气。不要再写 SnackBar 或引入 toast 包。
- `lib/widgets/AppDialogs.dart`：`AppAlertDialog`（参数与 `AlertDialog` 一致，另有 `subtitle`；全 App 对话框都用它，不要再写 `AlertDialog`，内容里的 ListTile、单选、复选和底部按钮样式都由它统一）、`AppDialogOption`（可点选项）、`AppDialogEmpty`（空状态）、`AppDialogCodeBlock`（路径等长文本）、`AppDialog` 和 `showAppNoticeDialog` / `showAppProgressDialog`。
- `lib/widgets/ExportStatsUi.dart`：导出图片共用的根（`ExportPage`）、头部（`ExportPosterHeader`、`ExportHeroSurface`）、分区标题（`ExportSectionTitle`）、面板和统计区域。导出图片的主题在导出抽屉里选（浅色 / 深色 / 纯黑，默认浅色，记住上次选的），不跟随 App 和系统：颜色从 `ExportPalette`（`lib/utils/ExportImageTheme.dart`）取，根部用 `ExportPage` 传主题，新导出图不要写死颜色。
- `lib/service/BackgroundExportService.dart`：导出图片一律走 `BackgroundExport.run`，不弹阻塞对话框，用户可以继续操作或离开页面，结束后顶部提示。任务里不能再读页面的 `widget`，需要的值在调用前取好。
- `lib/page/UpdateCalendarPage.dart`：更新日历，按落雪谱面级 `release_date` 把国服更新整理到月历上，落雪的 DX 谱 ID 要加 10000 才是项目内 ID。
- `lib/widgets/ImageLoadingIndicator.dart`：网络图片的加载占位（延迟淡入的小转圈，本地命中时看不到），新的网络图片都用它。
- `lib/widgets/Best50Ui.dart`：`Best50Hero`、`Best50Grid` / `Best50CoverCard`（三列曲绘卡）、`showBest50SongSheet`（推分面板）、`Best50AveragesCard`、`Best50IconAction` 等。

新组件加在这些文件里，别在页面里各写一份。Hub 页继续用 `HubComponents.dart`。

- `AnimatedChoiceBar`（老页面的等宽切换）与 `SegmentedTabs` 同一观感：凹槽底 + 白色滑块。选项放不下时缩小字号，不截断。

### 22.5 主导航：5 个标签

首页 / 曲库 / 成绩 / **游玩** / 我的。「游玩」是 `PlayZoneHubPage`：顶部分段切换「出勤 | 休闲」，两边就是原来的 `AttendanceHubPage` / `PlayHubPage`。标题和分段切换固定在外层不随内容滚动，切换时只有内容区过渡，转场复用 `MainNavigationViewport`。
`FeatureRegistry` 的分类（`'出勤'`、`'休闲'`）和收藏键**没有改**，首页搜索结果路径也照旧。三种导航栏样式（经典 / 液态玻璃 / 伸缩胶囊）都保留。

### 22.6 收藏（星标）

- 首页「常用」就是收藏列表：所有收藏都显示成图标（`FavoriteEditGrid`），任务进行中图标换成进度圈；线路和统计留在各自的 Hub 入口。正常态和编辑态共用一棵树，点「编辑」时图标不重新入场，只有叉号、提示和删除区域过渡；编辑态直接拖动换位置，点叉号或拖到下方删除区域移除。
- 成绩 Hub 顶部是设计稿的概览卡片，下面的「全部功能」保留每个功能的星标。**以后改 Hub 页不能把带星标的入口去掉。**
- 首页概览下面是自动同步和服务器状态两个小组件（`lib/widgets/HomeStatusWidgets.dart`，只在可见且前台时轮询，服务器状态每 3 分钟刷新）。搜索框常驻在小组件下方，右上角不再有搜索键；输入时概览和小组件收起，让搜索框升到结果上方。收起只换那一格的内容，搜索框在列表里的位置不变（§22.13）。
- 首页搜索框的范围（功能 / 歌曲 / 功能+歌曲，默认功能）在系统设置里选，存在 `SearchInteractionPreferences`；原位和展开两种交互都生效。
- 曲库 Hub 只是功能列表；搜索和筛选在 `SongSearchPage` 里，进入功能后才出现。

### 22.7 设置页的个性化功能必须继续生效

自定义背景图（选图后先进 `WallpaperCropPage` 裁剪，确认才替换旧壁纸，并用 `ColorScheme.fromImageProvider` 自动取色更新主题色）、装饰图透明度、白色覆层、主题色、深色 / 纯黑模式、导航栏样式与动画开关——这些是 App 的特色，**新 UI 不能绕开它们**：颜色一律取 `ColorScheme` / `AppSurfaces`，背景交给 `ThemeAwareBackground` / `BackgroundPageScaffold`，不要在页面里铺死一个不透明底色把用户背景图盖掉。

### 22.8 Best50 系列

- 页面有曲绘、双列、单列三种显示模式（`Best50DisplayPreference`，本地记忆，六个页面共用）。曲绘模式用 `Best50CoverCard`，单列用瘦长的 `Best50StripCard`；双列（`Best50ScoreCard`）和导出图片都用 `B50GameCardWidget`，改它会同时影响这两处。配色走 `B50CardPalette`：页面上跟随 App 的浅色 / 深色 / 纯黑，导出图片跟随导出抽屉里选的主题。
- 六个页面（Best50 / 拟合 / 个性化 / 个性化拟合 / 理想 / 自定义）都把数据换算成 `Best50CardData`，不要再各写一份卡片。

### 22.9 `SongInfoPage` 的拆分方式

`lib/page/SongInfoPage.dart` 只保留：字段、`initState` / `dispose` / `build`。其余方法按功能放在 `lib/page/song_info/` 下的 part 文件里，写成 `extension _Xxx on _SongInfoPageState`：

| 文件 | 内容 |
|---|---|
| `SongInfoLayout.dart` | 页面布局：全出血头图、成绩卡（含上分潜力）、关键数值、物量、基础信息、定数历史、谱面标签、四个标签页（成绩历史 / 数据 / 社区 / 工具）、贴底操作栏 |
| `SongInfoLoaders.dart` | 数据加载、解析与数值计算 |
| `SongInfoTables.dart` | 定数历史、成绩趋势、分布图、对照表、容错计算 |
| `SongInfoCommunity.dart` | 谱面评分与评论区 |
| `SongInfoActions.dart` | 分享 / 导出 / 跳转 / 收藏 / 笔记 / 上传 BV |
| `SongInfoWidgets.dart` | 统计项、物量格、徽章、别名等小部件 |

两条规则：

1. **扩展方法里不能直接调 `setState`**（protected，会报 `invalid_use_of_protected_member`），统一用 `_update(() { ... })`。
2. 扩展方法里**不能不带类名访问 static 成员**，所以原来的 `static` 常量（`_tapWeight` 等）已经提升为库级私有常量；新增常量也放在库级。

信息区域是盖在头图上的抽屉：头图固定不动，抽屉就是页面的滚动内容，松手时停在半路会吸附到收起或拉开（`_SongDrawerHero` 把头图裁到抽屉顶边以上，抽屉本身不铺底色，用户背景图能透出来）。

切换 ST / DX 在同一个页面状态里进行（`_switchSong` 预读 → `_onSongChanged` 同一帧换数据），数字滚动、文字淡入，不再叠两个页面。加载任务跑在带歌曲代数的 Zone 里，切走后迟到的结果由 `_update` 丢弃；新增的异步加载要走 `_update` 写状态。

版本和首次上线分国服、日服显示（`_buildRegionStat`）：日服来自 union；国服版本来自水鱼曲库，国服上线日期来自落雪曲目列表谱面级的 `release_date`，按当前谱面类型取。

信息分类：时长在关键数值；版本、BPM、谱师在基础信息；基础信息、物量、定数历史、谱面标签直接铺在页面上；成绩历史单独一个标签页；分布图、对照表在「数据」；评分和评论在「社区」；容错和计算器在「工具」。

切难度时成绩卡不重新入场：成绩、定数 / 拟合 / 平均达成、物量和绝赞数量用 `RollingNumber` 滚动，文字和徽章用 `FadeSwitcher` 淡入淡出。

⚠️ 同一个父节点下的 `ValueKey` 不能撞值：曾经给成绩卡用 `ValueKey(难度序号)`、给标签页内容用 `ValueKey(标签序号)`，切到 BASIC（0）时两者都是 0，框架直接报错。

### 22.10 文字不截断

Rating、达成率、歌名、说明文字这类重要内容不要用省略号。放得下多行就换行；单行放不下时，短文本用 `FittedBox(fit: BoxFit.scaleDown)` 等比缩小（`StatTile` 已内置），歌名这类长文本用 `MarqueeText`（§8）。

### 22.11 动效

入场用 `EntranceAnimation`（列表项按 `index` 错开，换 Key 重播），按压用 `PressScale`，参数照设计稿：Best50 卡片 14px + 缩放 0.96 / 420ms，成绩列表 8px / 300ms，搜索结果横向 10px / 320ms，首页 12px / 500ms，歌曲详情面板 10px / 350ms。两者都尊重系统「减少动态效果」。

### 22.12 KALEIDXSCOPE 门详情页

所有门共用 `lib/page/KaleidXScope/KaleidXScopeGatePage.dart`，门之间的差异写在文件顶部的 `_gateConfigs`（标题、门图、标记缓存键、接口缺字段时的兜底文案）和门接口的数据里，不要再为某个门单独写一份页面。

### 22.13 输入框所在的布局树不能随键盘变化

键盘弹出时不要切换页面结构，也不要把输入框放进会回收子项的 `ListView.builder`：输入框一旦被销毁就会丢焦点，键盘立刻收回。达成率计算器踩过这个坑。键盘只能影响留白和局部详略（§18）。

### 22.14 大数据量渲染不能阻塞交互

渲染几百上千条数据（如歌曲列表）时，要尽可能保证交互丝滑，不要阻塞 UI。

- 列表按需构建（`ListView.builder` / `SliverList.builder` / `SliverGrid`），不要放进 `Column`，也不要用 `shrinkWrap`。
- 耗时计算放到后台 isolate，或定期让出事件循环；大 JSON 用 `decodeJsonInBackground`；曲库查找用 `MusicDataIndex`，不要逐首遍历。
- 一次要构建很多行的离屏内容（导出图）用 `ExportProgressiveColumn` 分批挂载。
- 等待时用骨架屏、加载动画或过渡效果，已有内容尽量留在屏幕上；具体用哪种按场景决定。

### 22.15 多语言

- 全 App 使用 `lib/l10n/` 的 ARB 和 Flutter `gen-l10n`，覆盖简体中文、繁体中文、英语、日语；不自动翻译歌曲资料、服务端原文或用户内容。
- 文案通过 `context.l10n` 获取，带变量的文案使用 ARB 占位符；修改 ARB 后运行 `flutter gen-l10n`，不要手改生成的 Dart 文件。
- 语言偏好统一由 `AppLanguagePreferences` 管理，默认跟随系统；繁体中文需识别 Hant 以及 TW/HK/MO 区域，未知语言回落简体中文。不要新增字库或翻译 SDK。
- 界面、服务层提示（同步、上传、备份、导入导出、更新、OCR 等报错与进度）和系统通知均已迁移。服务层没有 BuildContext，用 `appL10n`；版本名、牌子汉字、流派、日志、匹配关键词等数据保持原文。比较或分支不得依赖提示文案（如 `用户取消同步` 这类哨兵值保持原文、OCR 用 `loginRequired` 判断登录失效），在后台 isolate（`compute`）里不要读 `appL10n`。断言中文提示的单元测试要先把 `platformDispatcher.localesTestValue` 固定为 `zh`。
- 枚举名称、筛选值、接口状态和缓存键继续使用原值，只在展示位置本地化。含译文的静态选项或后备提示应使用 getter 按当前语言生成，不得用 `static final` 缓存首次读取时的语言。
- 无 `BuildContext` 的客户端进度回调通过 `lib/l10n/AppMessages.dart` 读取当前语言；界面构建仍优先使用 `context.l10n`。不得在 `initState` 中依赖 `context.l10n`。
- 功能目录的中文标题仍是收藏键、分类键及跳转标识。显示时通过 `FeatureLocalizations` 取 ARB 文案，搜索同时匹配原文与当前语言；不得把译文写回功能模型或用于路由判断、收藏持久化和功能配色。
- 新增文案先查 ARB 有没有相同中文可复用；带变量的服务层文案用 `{p0}` 占位，修改后运行 `flutter gen-l10n`。
- 只给首屏的列表项加入场动画，滚动时不要反复播放。
