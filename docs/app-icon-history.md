# 应用图标回滚记录

## 2026-10-27 更换

- 当前图标：`assets/icon.png`，用户提供的绿色背景、抱着绿色玩偶的立绘，原图 1254 × 1254；未改绘画内容。
- 更换前原图：`assets/icon_history/2026-10-27-before/icon.png`，2048 × 2048 的黄绿色背景正面立绘。
- 旧原图 SHA-256：`fa05ed0ca08965a1f9961fe4c6d49fbe6b5fde21e72b224fe80739d00f0283ee`。
- 新原图 SHA-256：`3d8dff3f49b2770124a292993114f65c4d1c156f91158589dad3ed9ade1da2a1`。
- 完整本地快照：`.local-backups/app-icons/20261027-161303/`，包含原配置、Android／iOS／Windows／macOS／Web 图标与校验清单。该目录已忽略，不会被 Flutter clean 清掉。

当前使用 pubspec.yaml 的 flutter_launcher_icons 配置生成各平台图标，关于页沿用 assets/icon.png。回滚时优先按快照 manifest.json 恢复对应图标资源，并仅恢复原图标配置段；不要覆盖此后修改过的版本号、依赖或其它资源配置。需要移除本轮额外生成的文件时，仅按清单中的 newFiles 处理。

旧图保留在源码历史目录，未加入 Flutter 运行时资产列表。完整快照保留在本机；换电脑后仍可使用旧原图重新生成图标。

验证：已在原有依赖锁定下通过 Android release 构建，安装包版本为 2.9.0+52；包内 10 份 Android 图标资源及关于页原图均与新图生成结果核对一致。未进行真机安装或 iOS／桌面端运行验证。

## 2026-10-27 Android 完整画面适配

- Android 8.0 及以上的自适应前景在 XML 中四边各留 29% 相对空白，原图等比居中；背景使用原图边缘取样色 `#AECB92`。
- 对 108dp 图层，方图边长为 45.36dp，对角线小于 66dp，可完整落在安全圆内。使用相对比例适应不同桌面图标尺寸，不在原图上裁切或改绘。
- Android 系统仍按桌面形状遮罩图标外轮廓；绿色留白承受遮罩，整张方图保留在内部。人物显示会相应缩小。
- 本次适配前快照：`.local-backups/app-icons/20261027-163347-android-safe/`。回滚此适配时恢复 Android 图标 XML、图标背景色及对应配置行即可，原图无需更换。
- 原始图、iOS、macOS、Windows 和 Web 图标均保持原样。今后重新运行 flutter_launcher_icons 后，需保留 `mipmap-anydpi-v26/ic_launcher.xml` 的 inset 设置；普通 Flutter 构建不会重置它。

参考：https://developer.android.com/develop/ui/compose/system/icon_design_adaptive

## 2026-10-27 缩小 Android 留白（20%）

- 四边 inset 由 29% 调为 20%，画面宽高相对上一版增大约 43%，继续居中显示并保留浅绿色背景。
- 本版优先增大画面，不再按完整方图落在安全圆内的保守比例处理；圆形等系统遮罩可能裁到少量边角。
- 29% 版本备份：`.local-backups/app-icons/20261027-202841-android-inset-29/`。原图与其他平台资源保持原样。

## 2026-10-27 Android 留白 5%

- 按用户要求，Android 自适应图标四边 inset 从 20% 调为 5%。原图、背景色和其他平台资源保持原样。
- 20% 版本备份：`.local-backups/app-icons/20261027-203150-android-inset-20/`。

## 2026-10-27 Android 留白 13%

- 按用户要求，Android 自适应图标四边 inset 从 5% 调为 13%。原图、背景色和其他平台资源保持原样。
- 5% 版本备份：`.local-backups/app-icons/20261027-203440-android-inset-5/`。

## 2026-10-27 Android 留白 17%（当前）

- 按用户要求，Android 自适应图标四边 inset 从 13% 调为 17%。原图、背景色和其他平台资源保持原样。
- 13% 版本备份：`.local-backups/app-icons/20261027-203635-android-inset-13/`。

### 应用内图标同步

SplashPage 与 AboutAppPage 共用 `lib/widgets/AppLauncherIcon.dart`，前景四边留白 17%，并采用 Android 108dp 图层／72dp 可视区换算及同一浅绿色背景。页面原有图标尺寸不变；以后调整 Android 留白时同步修改该组件常量。
