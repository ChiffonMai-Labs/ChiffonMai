# Issue #4：HyperOS 小窗黑屏复查

## 2026-10-23 结论

报告者对比了 v1.11.1（正常）与 v2.8.0（异常）。本地 `log.txt` 是经整理的原始日志节选，不是完整录制。本轮尚无对应设备，不能确认根因或宣称修复。

- 两版均使用 Impeller/Vulkan，且在启动、进入小窗和退出小窗时均出现相同的 gralloc 格式 59 / 4×4 缓冲分配失败。成功的旧版也有这些警告，不能单独据此禁用 Impeller。
- 两版均完成了 SurfaceView 更换和 `VRI.reportDrawFinished`。该日志证明 Android 窗口绘制协调完成，不能证明 Flutter 主体已经可见。
- 新版进入小窗后仍有输入事件；节选没有包含足以定位 Flutter 布局异常、页面透明度或渲染停滞的调用栈。
- 包名从 `com.example.my_first_flutter_app` 变为 `cloud.chiffonmai.app`，系统适配状态也可能不同；目前没有证据证明它是原因。不能为排查回退包名、签名、单实例配置或预测性返回防护。

历史对比使用本地提交 `06f22a8`（v1.11.1）与 `caf217b`（v2.8.0-beta）。它们只用于代码差异分析，不能证明与报告者安装包的构建环境完全一致。

## 本轮候选防护与诊断

- `MainNavigationViewport` 在窗口尺寸变化时收尾未完成的淡入滑动动画，保证当前页恢复不透明，同时保留全部页面状态。只在尺寸变化时处理，不增加常驻 ticker。
- 根组件记录窗口物理尺寸、像素比、inset、生命周期、是否允许帧调度，以及窗口变化后的 Navigator 布局尺寸。
- 应用内日志保存 Flutter 布局异常和未处理异常的调用栈，继续调用原错误处理器。

这些改动用于消除过渡停留风险并补足证据，尚未证明它们能解决报告者的小窗黑屏。

## 针对性复测

在同一设备上分别录制：全屏进入小窗、切换底部选项卡、小窗缩放、退出小窗、从后台恢复。请覆盖导航动画开启与关闭两种状态，尤其在切换动画尚未结束时进入小窗。

若仍黑屏，保留未经筛选的 `adb logcat -v threadtime -b main -b system -b crash`，并在复现后从应用导出日志。需要看到同一时间段的 `[Window]`、`[FlutterError]`、`[UnhandledError]`；避免再次只筛 Surface/gralloc 行。对比全屏、小窗的实际布局尺寸和帧完成记录后，再决定是否需要原生 Surface 或渲染后端方面的兼容措施。

参考：[Issue #4](https://github.com/ChiffonMai-Labs/ChiffonMai/issues/4)、[小米自由窗口适配说明](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1593)。

## v2.9.0 日志能力复核（2026-10-27）

- 已读取 issue #4 及全部评论：报告者在 v2.8.0 仍可复现；现有附件是经过整理的原始日志节选，不能据此确认根因。
- 应用日志包含 Flutter 异常、未处理异常、窗口变化事件、当前物理／逻辑尺寸、像素比、inset、刷新率、生命周期、帧调度与导航偏好。
- 最多保留 2000 条、约 256K 字符的当前记录，单条过长会截断；每两秒持久化近期尾部，导出时等待写入。重启后可以附上有限的上次会话记录；异常退出可能丢失尚未写盘的最后片段。
- 导出对常见 Token、密码和二维码进行脱敏；提交前仍需检查个人信息。日志本身不纳入数据备份。
- 应用内导出不能获取完整 Android Surface／Vulkan／系统窗口日志；需要时仍应录制未经筛选的 adb logcat。
- 未连接 HyperOS／Android 真机，未验证小窗问题已修复；发布后回复草稿见 `issue-4-reply-2.9.0.md`，尚未发送。

## v3.0.0-alpha 日志复核（2026-11-07）

- 报告者（REDMI K80，HyperOS 2.0.9.0）在 v3.0.0-alpha 仍可复现。新日志显示：刚进入小窗的那一帧布局正常（节点 713、窗口内文字 42），App 收到 `resumed` 后约 0.3 秒的补画里，节点降到 342、窗口内文字只剩 10，也就是导航栏还在、页面内容消失。上次会话的记录完全相同（695 → 339）。
- 退出小窗回全屏的第一帧，系统报出 `padding T1989 B64`（物理像素），比小窗高度 1728 还大。v3.0.0-alpha 只在窗口尺寸变化时记日志，尺寸不变的安全区变化没有记录。
- 推断：恢复时 App 调用 `applySystemUiMode()`（`setEnabledSystemUIMode(edgeToEdge)` 加原生 `controller.show(statusBars)`），HyperOS 2.0 随后给小窗报出比窗口还高的顶部安全区，页面内容被整体推到窗口外。这条推断与「v1.11.1 正常、v2.7.x 起异常」吻合：恢复时重设系统栏是 v2.7.0 加入的。尚未在设备上验证。
- 本轮修改：
  - 根部 `MediaQuery` 经过 `WindowDiagnostics.sanitizePadding`：某一侧安全区超过窗口对应边长的三分之一时按 0 处理，并记 `[Window] 安全区异常已忽略`。
  - `MainActivity.applyStatusBarVisibility()` 在小窗 / 分屏（`isInMultiWindowMode`）中不再控制状态栏。
  - `didChangeMetrics` 在尺寸不变、安全区变化时也记 `[Window] 安全区变化`，下次日志能直接看到数值。
