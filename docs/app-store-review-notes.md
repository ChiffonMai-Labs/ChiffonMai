# App Store 2.1「需要更多信息」回复材料

> 成稿与可直接上传的素材在 `app_store_submission/`（备注、文案、隐私答案、截图、IPA）。本文件保留完整分析与背景。

> 目标：一次性满足本轮 Information Needed 的 6 项要求，并避开 1.2（UGC）与 5.1.1(v)（账号删除）的二次被拒。
> 提交前必须填写的占位符用 `{{...}}` 标出。

---

## A. 提交前注意事项

> 本轮已补：App 内「删除账号」页、评论举报与屏蔽、已屏蔽用户管理。下面 A0 保留原分析，B 部分已按新实现写。

### A0. 原分析（现已实现）


**账号删除（5.1.1(v)）——有条款依据，但仍取决于审核员怎么认定。**

Guideline 5.1.1(v) 的前提是「App 支持创建账号」。本 App **不创建账号**：水鱼、落雪、AWMC NET 的账号都在各自网站/机器人创建，App 只保存本地登录态。可以按下面口径回答，不改代码：

- App 内的删除入口就是「我的 → 绑定与授权管理 → 对应数据源 → 登出」。登出会删除本机账号档案、令牌、成绩缓存，并撤销服务端自动同步任务（代码确实如此：`AccountSwitchService.clearAccountData` 会先 `AutoSyncService.disableForSource`，再 `AccountStore.remove`）。录屏中完整展示确认弹窗与执行结果。
- 第三方平台账号在对应平台注销（水鱼 / 落雪 / AWMC NET 的账号页或交流群）。
- ChiffonMai 服务端残留的评论、评分、排行榜与社区资料，按隐私政策第六节发邮件申请删除，15 个工作日内处理。
- 在备注中主动写清「账号由第三方创建，App 不收集邮箱/密码明文；登出即删除 App 侧账号数据」。

**UGC 举报与屏蔽（1.2）——只能争取，不能保证。**

现有能力：敏感词/手机号预过滤、删除自己的评论与评分、问题反馈问卷、邮箱与 QQ 群。缺的是「一键举报」和「屏蔽作者」。不改代码时，备注里如实写「举报经反馈问卷/邮箱处理，评论经前置过滤并由维护者人工清理；当前未提供按用户屏蔽」，并录屏展示过滤拦截、删除自己的评论、反馈入口。

风险：审核员若严格按 1.2 四条检查，屏蔽缺失可能再被拒一次。真再拒时，再补 A1/A2 中的最小代码即可。

### A1. 如果被要求补代码：账号删除（5.1.1(v)）

现状：App 只有「登出」，没有「删除账号」；账号本身在第三方查分器网站注册。审核要求的是**在 App 内发起删除**。

最小实现（建议）：

- 入口：`我的 → 绑定与授权管理 → 删除账号`。
- 确认对话框说明三件事：删除后本机账号档案、令牌、成绩缓存会被清除；第三方平台上的账号不会被删除，需要到对应网站操作（给出水鱼 / 落雪 / AWMC NET 的账号页链接）；选择继续则同时向服务端登记删除请求。
- 执行：对每个已绑定数据源复用 `AccountSwitchService.clearAccountData(source, clearCredentials: ...)`（内部已先撤销自动同步任务、移除账号档案与游玩次数）；再删 `SecureCredentialStore` 其余键（`luoxueAccessToken/RefreshToken`、`awmcNetImportToken`、`awmcQuickIdentities`、`autoSyncTasks` 等，建议加 `deleteAll()`）、成绩/排行榜/曲库缓存，最后回首页提示。水鱼同时走 `UserProfileNotifier.clearShuiyuAccountCache()` 清理内存快照。
- 服务端：先按账号身份调用已有接口删除 `GET/DELETE /api/comments/user`、`DELETE /api/rankings/user/{id}`、`DELETE /api/song-rankings/player/{id}` 与逐谱面 `DELETE /api/ratings/{songId}/{level}`；失败的类别保留在结果页，用预填邮件申请删除（隐私政策承诺 15 个工作日）。

### A2. 如果被要求补代码：UGC 举报与屏蔽（1.2）

现状：谱面评论/评分是 UGC；已有敏感词与手机号前置过滤（`lib/utils/CommentTextValidator.dart`）、可删除自己的评论与评分，但**没有举报，也没有屏蔽其他用户**。

最小实现（建议）：

- 举报：非本人评论增加「举报」→ 选择原因（广告 / 辱骂 / 剧透 / 其他）→ 生成一封带歌曲、难度、评论 ID、作者、正文的邮件给维护者（`ExternalLaunchUtil` 打开 `mailto:`，失败则复制内容并提示）。歌曲详情与「最近评论」共用同一入口（最近评论页目前只过滤，不重复放菜单）。
- 屏蔽：评论菜单「屏蔽该用户」→ 按 `CommentItem.dataSource + originalId` 本地保存（不按昵称），在 `_loadComments()` 与最近评论结果里过滤；设置 → 其他 →「已屏蔽用户」可解除。
- 审核说明里写清：前置过滤 + 人工处理 + 反馈入口（`我的 → 反馈与支持 → 问题反馈` 问卷、QQ 群、`chiffonowo@foxmail.com`）。
- 补一个简短的「社区规范」对话框或页面（评论/评分/昵称规则、举报与处理方式），入口放歌曲详情评论区与设置页。

> 不写代码时就按 A0 的现状口径回复；补了代码再把 B7、D 的对应句子改强。

### A3. 其余提交前准备（不需要改功能）

- [ ] 真机（最新 iOS）用 TestFlight 构建完整走一遍，确认无崩溃。
- [ ] 准备演示账号（见 B3），提前验证公开查询、成绩拉取、评论、删除均可用。
- [ ] 录屏（见 C），从点图标启动开始，一镜到底或分段后合并。
- [ ] 更新 App Store 截图：必须出现真实界面与数据，不能只有标题图、登录页或启动图（2.3.3）。
- [ ] App Privacy 问卷按实际勾选：账号标识、成绩、用户内容、照片（结算 OCR）、位置（地图）、诊断。
- [ ] 年龄分级按 UGC 与多人游戏如实填写；App 内无内置浏览器，外链均跳系统浏览器。
- [ ] 补「社区规范」入口（评论规则、举报与处理方式）——纯文案，可复用现有问题反馈页。
- [ ] 确认归档内包含隐私清单（`PrivacyInfo.xcprivacy`，UserDefaults / 文件时间戳等 required-reason API）；仓库当前没有该文件，需新增并随包提交。
- [ ] 用户协议四语点名 SEGA、关于页补「与 SEGA 无隶属关系」，并给三份许可证文件加入口（见 B6）。
- [ ] 关于页增加 Flutter 开源许可页（`showLicensePage`），并给 Font Awesome（CC BY 4.0）补署名；目前全 App 没有许可页。
- [ ] 隐私政策第三方清单补 Google Fonts（`fonts.gstatic.com`，启动时下载字体），并把 api.wmc.pub、下载/镜像域、外部地图、TestFlight 等实际流量补全。
- [ ] 补 `NSHumanReadableCopyright`（可选，但建议）。
- [ ] 评估 4.8：登录身份来自第三方平台（水鱼密码、落雪 OAuth）。若被追问，说明这是外部平台账号而非 App 自建账号；被要求时再接 Sign in with Apple。
- [ ] ATS 目前 `NSAllowsArbitraryLoads=true`，业务全为 HTTPS，可保留；被追问时说明为兼容第三方资源域。
- [ ] `NSMicrophoneUsageDescription` 目前没有实际录音调用，可保留；其余权限文案与用途一致。

### A4. 演示账号怎么准备

1. 新注册一个水鱼查分器小号，按 `我的 → 账号注册引导` 的第 2 步绑定 QQ。
2. 关闭「禁止公开接口使用我的成绩」，否则 App 拉不到记录；保留「公开我的成绩」。
3. 让账号至少有十几条成绩（导入或同步均可），并保留至少一张谱面可用来演示评分与评论。
4. 如还要演示上传，准备该账号的 ImportToken，填入凭据页并确认可同步。
5. 把用户名/密码填进 App Store Connect 演示账号字段；账号不要写入公开仓库。

---

## B. 可直接粘贴到「App 审核信息 → 备注」的文本（中文）

**联系人**：ChiffonOwO，chiffonowo@foxmail.com

> 从下面这一行起，到 B8 结束，整段粘贴进「备注」字段。

### B1. 录屏

真机：{{DEVICE}}，iOS {{IOS_VERSION}}，TestFlight 构建 {{BUILD}}。
录屏地址：{{RECORDING_URL}}

录屏从点击 App 图标启动开始，依次演示：首次引导与权限、无账号浏览曲库与歌曲详情、谱面预览、账号注册引导、评论发布与删除、敏感词拦截、举报评论、屏蔽作者、登录演示账号、拉取成绩、Best50、Rating 计算器、支持开发者页、删除账号（含服务端清理结果与邮件兜底）。

### B2. 应用用途与目标受众

ChiffonMai 是面向街机音游《舞萌 DX》（maimai DX）玩家的第三方非官方工具箱，解决官方客户端缺少的曲库检索、成绩分析、Rating 计算与练习规划问题。

目标受众是舞萌 DX 玩家与音游社区，主要为 12 岁以上、能理解成绩与 Rating 概念的用户。App 把玩家原本分散在多个网站的工具集中到一处：查歌与谱面、成绩与 Best50、上分推荐、谱面预览、猜歌、机厅地图和成绩同步。App 免费、无广告、无内购。

### B3. 设置与主要功能访问

**大多数功能无需账号**：启动并完成引导后，可直接使用曲库搜索、歌曲详情、谱面代码与预览、Rating / 达成率计算器、推荐、猜歌、收藏夹、机厅地图和设置。曲库数据来自公开接口，首次打开需要联网。

**需要账号的功能**（个人成绩、Best50、评论与评分、成绩同步）：使用演示账号。

- 水鱼用户名：{{DEMO_ACCOUNT}}
- 水鱼密码：{{DEMO_PASSWORD}}

步骤：

1. 底部「我的」→「绑定与授权管理」→「水鱼」→ 输入上面的用户名和密码登录。
2. 返回「我的」→「拉取成绩并更新数据」→ 选择水鱼 → 确认。等待曲库与成绩下载完成。
3. 首页出现 Rating 与 Best50 后，可查看 Best50、成绩查询、排行榜与个性化推荐。
4. 打开任意歌曲 →「社区」标签可查看评论与评分；账号有该谱面成绩时即可评分与发表评论。

说明：

- 账号由第三方免费查分器「水鱼查分器」提供，App 内不注册；「我的 → 账号注册引导」提供水鱼、落雪与 AWMC NET 的分步图文注册说明。
- 演示账号已开启公开成绩查询、绑定 QQ，并保留若干成绩；完整展示需要网络。
- 如需测试同步上传，演示账号已预留成绩导入 Token（{{IMPORT_TOKEN_NOTE}}）。
- 自动同步是可选功能（默认关闭），服务端托管导入凭据；`我的 → 自动同步` 可随时关闭，关闭时凭据随之删除。
- 若水鱼账号临时不可用，曲库、计算器、猜歌与地图不受影响；也可改用「落雪」授权（外部浏览器 OAuth）。

### B4. 外部服务与数据用途

所有第三方均为免费公开服务；App 不向其提交与功能无关的数据。

| 服务 | 用途 | 传输的数据 |
|---|---|---|
| chiffonmai.cloud（本项目后端） | 水鱼 OAuth 与成绩读取代理、公开曲库代理、评论/评分、排行榜、公告、加载语录、友链、更新日历、翻译代理、收藏品图片、自动同步任务 | 账号标识、令牌、成绩、评论/评分、必要资源 ID、网络日志 |
| 水鱼查分器 diving-fish.com | 水鱼账号登录、成绩读取与上传 | 用户名/密码换取的令牌、QQ、成绩 |
| 落雪咖啡屋 maimai.lxns.net | 落雪授权、成绩读取与上传、曲目/收藏品/资源 | OAuth 授权码与令牌、好友代码、成绩、资源 ID |
| AWMC NET net.wmc.pub | AWMC NET 成绩读取与上传、谱面资源 | QQ、导入 Token、成绩、谱面 ID |
| maimai Score Hub maimai.bakapiano.com | 扫码登录、成绩图片 OCR、成绩读取 | 登录令牌、玩家标识、结算画面照片 |
| DXRating.net（含 miruku / shama 资源域） | 定数历史、全局标签、备用曲绘 | 资源请求 |
| AWMC 谱面服务及公开 CDN | 社区别名、歌曲详情的谱面标签、曲绘 | 公开资源请求 |
| Union（godserver.cn） | 曲目与地区元数据 | 资源请求 |
| Yuri-YuzuChaN 别名数据（yuzuchan.moe） | 歌曲别名 | 资源请求 |
| AWMC 图鉴与资源（api.wmc.pub、download.wmc.pub、v.wmc.pub） | 收藏品、谱面与音源资源 | 资源 ID 请求 |
| NearCade nearcade.cn | 全球机厅数据 | 查询区域 / 机厅 ID |
| 高德地图（webrd0x.is.autonavi.com 等） | 地图瓦片 | 所浏览区域的瓦片请求 |
| 系统地图（Apple Maps / 高德 / Google Maps） | 点击机厅后的外部导航 | 目的地坐标 |
| 百度翻译（经后端） | 界面外文本翻译 | 待翻译文本与语言 |
| 哔哩哔哩 | 谱面相关视频搜索与打开 | 搜索词、视频 ID |
| isMaiDown | 舞萌服务器状态 | 状态查询 |
| Google Fonts（fonts.googleapis.com / gstatic） | 运行时下载字体 | 字体资源请求 |
| GitHub Releases / API、gh-proxy.com、ghfast.top、蓝奏云、TestFlight | 版本检查、Android 安装包下载与 iOS 测试版入口 | 版本查询、下载请求 |
| 爱发电、微信赞赏码、QQ、问卷、画加、B 站、Gitee | 赞助与外部链接 | 浏览器打开链接 / 扫码 |

数据保存：令牌放系统安全存储，成绩与曲库缓存保存在本机；选择参与排行榜时成绩会上传本项目后端。位置仅用于地图，不上传到本项目后端。曲绘识别在本机用 pHash 完成；只有「结算画面识别」会把拍摄的照片上传 maimai Score Hub。完整说明见隐私政策：`https://chiffonmai.cloud/privacy`（应用内「我的 → 关于 APP → 隐私政策」同文）。

### B5. 地区差异

App 面向中国大陆玩家，同时提供简体中文、繁体中文、英文、日文，默认跟随系统语言，未知语言回落简体中文。各国界面均可正常使用，没有区域锁。

地区差异仅体现在数据内容：歌曲同时保留国服与日服版本、上线日期和收录差异；水鱼账号是中国大陆版本的记录，落雪与 AWMC NET 也以国服数据为主；地图使用高德瓦片，海外访问可能略慢，导航在中文区优先高德/百度/腾讯地图、境外优先 Google / Apple 地图，全球机厅数据（NearCade）与其余功能不受影响。iOS 的更新走 App Store / TestFlight；Android 额外的应用内更新与桌面小组件不影响 iOS 功能完整度。

### B6. 第三方内容与权利

- ChiffonMai 是个人开发的非官方工具，与 SEGA 没有隶属或官方合作关系；代码以 MPL-2.0 许可证开源。
- 《舞萌 DX》的名称、商标、曲绘、音频与谱面归 SEGA 等各自权利人。App 从水鱼、落雪、DXRating.net、Union、AWMC NET 等公开数据服务读取或缓存这些资料，仅用于查询、展示与玩家的个人整理，不售卖。
- 应用内《用户协议》第六节写明第三方内容权利归属与导出内容的使用边界；「关于 APP → 致谢」逐项列出数据来源与许可证（含 `simai_flutter` 的 MIT 与第三方声明）；「关于 APP」常驻用户协议、隐私政策入口。
- 可提供：用户协议、隐私政策、致谢页截图、`simai_flutter` 与 Outfit 的许可证文本。

> **现状缺口（提交前补）**：`assets/legal/*.md` 四语里只写「游戏名称、商标归各自权利人」，从未点名 SEGA；README 与官网虽有「与 SEGA 没有隶属关系」，但两者都没有打包进 App。需要在用户协议四语中补一句「《舞萌 DX》及其名称、商标、曲绘、音频归 SEGA 等权利人所有，本应用与 SEGA 无隶属关系」，或在关于页加同义常驻声明。包内的 `simai_flutter_MIT.txt`、`simai_flutter_THIRD_PARTY_NOTICES.md`、`outfit_OFL.txt` 目前没有被任何页面链接，需在关于页加许可证入口。

### B7. 账号体系、删除与 UGC

- 账号来自第三方查分器，App 内通过「账号注册引导」说明注册步骤。登录方式分别为：水鱼用户名+密码（仅用于换取令牌，不落盘明文）、落雪浏览器 OAuth 授权、AWMC NET 的 QQ + 导入 Token / 机台二维码、maimai Score Hub 扫码。App 不自建账号，也不保存密码明文。
- 「我的 → 绑定与授权管理」可以分别解除各数据源的登录/授权。
- **「我的 → 删除账号」** 会列出本机保存的账号，确认后：删除该账号的评论、评分与排行榜记录（尽力调用服务端接口）、撤销自动同步任务、删除本机账号档案/令牌/成绩缓存。页面同时写明第三方平台账号不随之删除，并给出水鱼 / 落雪 / AWMC NET 的入口；服务端未能自动删除的项会列出原因，并提供预填好的邮件申请入口（隐私政策承诺 15 个工作日内处理）。
- 评论限 500 字，提交前经敏感词、手机号与常见缩写过滤；每人每谱面一条评分，评分需已有该谱面成绩。
- 可删除自己的评论和评分；**任何评论都可「举报」（选原因后生成邮件给维护者），也可「屏蔽该作者」**，被屏蔽者的评论从歌曲评论区与最近评论中隐藏，设置页「已屏蔽用户」可解除。
- 多人猜歌没有内置聊天，只显示昵称与社区头像，因此公开文本只有评论、评分与昵称/头像。
- 评论区与设置页提供简短的社区规范说明。

### B8. 付费

App 完全免费，无内购、订阅、会员、广告与追踪。唯一涉及支付的是「支持开发者」页：微信赞赏码（静态图片）与爱发电外链，均为自愿赞助，不解锁任何功能，因此没有需要随版本提交的内购项目。

---

## C. 录屏分镜（真机、最新 iOS、TestFlight 构建）

一次录制完成，开始前把系统语言设为简体中文，关闭通知打扰。视频不要剪辑掉中间过程；如果需要分段，按下面的段号合并。

1. 桌面点击图标启动 → 完整走完引导：3 页介绍 → 逐项权限（允许相册、相机、通知；位置可选）→ 阅读并勾选协议 → 完成。
2. 首页展示 Rating 概览、常用功能、自动同步与服务器状态；上下滑动一次。
3. 底部「曲库」→ 搜索一首歌 → 打开歌曲详情：曲绘、难度切换、物量、谱面标签；进入谱面预览后返回。
4. 「社区」标签：展示评论与评分分布。先用演示账号发一条评论；再故意输入含敏感词的内容，展示被拦截。
5. 删掉刚发的评论；对另一用户的评论点「举报」，选择原因并提交邮件；再点「屏蔽」，回到列表确认其评论消失。
6. 「我的」→「账号注册引导」→ 依次切换水鱼 / 落雪 / AWMC NET 三个标签，展示分步图文（可点「前往网站」在浏览器展示注册页后返回）。
7. 「我的」→「绑定与授权管理」→「水鱼」→ 用演示账号登录。
8. 「我的」→「拉取成绩并更新数据」→ 选择水鱼 → 确认，等待完成。
9. 首页 Rating 有数据 → 打开 Best50，滚动；打开单曲 Rating 计算器，输入参数得到结果。
10. 「我的」→「反馈与支持」→「支持开发者」，展示赞赏码与爱发电按钮。
11. 「我的」→「删除账号」→ 展示将删除/保留的内容与外部平台入口 → 确认删除 → 等待结果页，展示评论/评分/排行删除数量与邮件兜底按钮。
12. 「我的」→「系统设置 → 其他 → 已屏蔽用户」展示列表并解除刚才的屏蔽（也可在删除前录）。

录制后另存 6.9 英寸与 6.5 英寸截图：首页、曲库搜索结果、歌曲详情、Best50、谱面预览、支持开发者。

---

## D. English version (for the review team)

**Contact**: ChiffonOwO, chiffonowo@foxmail.com

**Screen recording**: {{DEVICE}}, iOS {{IOS_VERSION}}, TestFlight build {{BUILD}} — {{RECORDING_URL}}. It starts at app launch and shows onboarding, browsing without an account, song detail, chart preview, the account-registration guide, posting/deleting a comment, the sensitive-word filter, reporting a comment, blocking its author, demo-account login, score refresh, Best50, rating calculator, the support page and the Delete Account flow (including server-cleanup results and the email fallback).

**Purpose & audience**: ChiffonMai is an unofficial companion app for the arcade rhythm game *maimai DX*. It gives players the song library, score analysis, Rating calculation, practice planning, chart preview, mini-games and arcade maps that the official client lacks. Audience: maimai DX players aged 12+, mostly the Chinese rhythm-game community. Free, no ads, no IAP.

**Access**: Most features need no account. For personalized features use the demo account `{{DEMO_ACCOUNT}}` / `{{DEMO_PASSWORD}}`: Profile → Bindings & Authorization → Diving Fish → sign in → Profile → Pull scores and refresh data → confirm. Then open any song → Community to rate/comment. Accounts are free third-party score trackers; in-app "Account registration guide" walks through sign-up.

**External services**: chiffonmai.cloud (own backend: OAuth proxy, public chart proxy, comments, rankings, announcements, auto-sync, translation proxy); Diving Fish; LXNS; AWMC NET; maimai Score Hub (includes score-photo OCR); DXRating.net; AWMC chart tags, community aliases and covers; Union; YuzuChaN fallback aliases; NearCade; AMap tiles; Baidu Translate (via backend); Bilibili; isMaiDown; Google Fonts; GitHub Releases. Details and data types: B4.

**Regional differences**: UI in Simplified/Traditional Chinese, English and Japanese, following the system language. No region lock. Data keeps separate CN/JP releases and dates; accounts are mainly CN-side; AMap tiles may be slower abroad. iOS updates via App Store/TestFlight.

**Third-party rights**: unofficial, MPL-2.0-licensed fan tool, not affiliated with SEGA. Game names, art and audio belong to their owners and are read from public data services for personal reference only. See the in-app User Agreement §6 and the in-app credits.

**Accounts/deletion/UGC**: ChiffonMai does not create accounts. Identities come from third-party trackers (Diving Fish username/password used only to obtain a token; LXNS OAuth; AWMC NET QQ + token/QR; Score Hub QR). Profile → Delete Account lists the saved accounts; confirming deletes their comments, ratings and ranking records (best-effort via the server), revokes auto-sync and clears the local profile, tokens and score cache. Third-party accounts stay on their platforms (links shown); anything not deleted automatically is listed with a pre-filled email request (15 business days per the Privacy Policy). Bindings & Authorization can unlink each source. Comments are limited to 500 chars and pre-filtered; users can delete their own comments and ratings, report any comment (reason → email to the maintainer) and block its author (unblock under Settings → Blocked users).

**Payment**: fully free; voluntary donations via a WeChat QR image and an Ài Fā Diàn link, no feature gating; no IAP configured.

---

## E. 提交前自检

- [ ] 删除账号、举报、屏蔽已在真机走通；B 中路径与按钮文字与实际一致。
- [ ] 演示账号可用、有成绩、可评论与删除；凭据同时填在 App Store Connect 的「演示账号」字段，不只写在备注里。
- [ ] App Store Connect「App 审核信息」勾选「需要登录」，联系人填写可用邮箱与电话。
- [ ] 录屏与截图均为真机、最新系统、当前提交构建。
- [ ] App Privacy 问卷与隐私政策、实际流量一致。
- [ ] 版本说明写明本次修复了审核反馈。
- [ ] 归档无隐私清单警告、无崩溃。
