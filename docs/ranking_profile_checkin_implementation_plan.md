# ChiffonMai 排行榜用户资料与自动签到等级系统实现计划

> 本文只描述实现方案，不修改业务代码、不连接生产环境。
>
> 生产环境凭据不得写入代码、Git、.env.example 或此文档。部署时通过服务器环境变量或安全配置文件注入。由于凭据曾直接出现在聊天内容中，正式实施前建议更换 SSH 密码。

## 1. 功能范围

实现：排行榜用户行可点击；刷新数据时可选择是否公开简要资料；公开资料显示头像、昵称、数据源、称号、背景、姓名框、等级和 Rating；每日首次成功进入 App 后自动签到；服务端记录签到、连续签到和经验值。

不实现手动签到、复杂任务/成就、成绩或收藏奖励、补签和等级限制。

## 2. 身份模型

服务端使用 account_key 作为用户主键：

    account_key = data_source + ":" + original_id

例如：shuiyu:123456、luoxue:abcdef。签到、等级和公开资料都使用 account_key，不能只使用 originalId。签到接口必须复用现有认证机制；服务端最终以 Token 身份为准，不能相信客户端提交的用户 ID、日期、连续天数或经验值。

## 3. 数据库设计

### 3.1 player_profile

增加或确认：account_key（唯一）、profile_visibility、profile_revision、title_id、background_id、nameplate_id、avatar_id、nickname、updated_at。

旧用户迁移默认：

    profile_visibility = false
    title_id = null
    background_id = null
    nameplate_id = null

### 3.2 player_checkin

字段：id、account_key、checkin_date、checked_in_at、streak_day、xp_earned、xp_total_after、created_at。

必须建立唯一约束：

    UNIQUE(account_key, checkin_date)

### 3.3 等级字段

可放入 player_profile，也可单独建 player_level：total_xp、level、active_days、current_streak、max_streak、last_checkin_date、updated_at。

active_days 是成功自动签到的日期数，不是安装天数或打开次数。

### 3.4 Rating 快照

简要资料需要 Best50、Best35、Best15 总 Rating，以及 Best35 B1、Best15 B1。建议服务端保存或计算：

    best50Rating
    best35Rating
    best15Rating
    best35B1 { songId, songName, difficulty, rating }
    best15B1 { songId, songName, difficulty, rating }
    ratingUpdatedAt

B1 定义为对应分组内单曲 Rating 最高的成绩；同分依次按达成率、单曲定数、songId 稳定排序。

## 4. 自动签到规则

### 4.1 触发时机

客户端在 App 启动、账号恢复完成、首页或 System Hub 基础加载成功后异步触发：

    App 启动
    → 恢复当前账号
    → 首页/System Hub 基础加载成功
    → GET /api/checkin/status
    → 今日未签到时 POST /api/checkin/auto
    → 更新本地等级和经验

不显示签到按钮，不弹确认框。可以在 System Hub 等级区域显示一次轻量提示，例如“今日已自动签到 +10 XP”。

成功进入 App 的判定：基础初始化完成、账号身份确定、首页或 System Hub 可以正常展示、认证仍有效。启动崩溃、Token 失效、账号未恢复、服务端不可访问均不增加经验。自动签到失败不阻塞 App，下一次成功启动重试。

### 4.2 日期和连续签到

服务端固定使用 Asia/Shanghai，不能使用客户端提交日期。

- 当日已签到：不增加经验。
- 上次签到是昨天：连续天数加一。
- 其他情况：连续天数重置为 1。
- 每个成功签到日期使 active_days 加一。
- max_streak 保存历史最大值。
- 不实现补签。

经验规则：

| 连续天数 | 当日经验 |
|---|---:|
| 1 | 10 |
| 2 | 12 |
| 3 | 14 |
| 4 | 16 |
| 5 | 18 |
| 6 | 20 |
| 7 及以后 | 22 |

公式：xp = min(10 + (streakDay - 1) × 2, 22)。经验只能由服务端计算。

### 4.3 等级

每一级升级所需经验：

    levelRequirement(level) = 100 + 25 × (level - 1)

累计阈值：

    threshold(1) = 0
    threshold(n) = 100 × (n - 1) + 12.5 × (n - 1) × (n - 2)

建议最大等级暂设 Lv.100。等级只表示使用 ChiffonMai 的参考，不代表实力，也不限制功能。

## 5. 后端 API

### 5.1 查询签到状态

    GET /api/checkin/status
    Authorization: Bearer <token>

返回 serverDate、timezone、checkedInToday、lastCheckinDate、currentStreak、maxStreak、activeDays、totalXp、level 和 levelProgress。

### 5.2 执行自动签到

    POST /api/checkin/auto
    Authorization: Bearer <token>
    Content-Type: application/json

请求体为空。首次签到返回 checkinDate、streakDay、xpEarned、totalXp、level、levelUp、activeDays、nextLevelXp、remainingXp。重复请求返回 alreadyCheckedIn=true、xpEarned=0。

签到必须在数据库事务中完成，并依靠唯一约束处理并发请求。

### 5.3 获取简要资料

    GET /api/rankings/user/:userId/brief-profile?dataSource=shuiyu

公开时返回头像、昵称、数据源、称号、背景、姓名框、等级、使用天数、Rating 快照和 profileRevision。

关闭时返回：

    { "success": true, "visible": false, "reason": "profile_hidden" }

关闭时不能返回 Rating、等级、头像、背景、称号或姓名框。

### 5.4 更新公开状态

    PUT /api/player/profile/visibility
    Authorization: Bearer <token>

请求体：

    { "profileVisibility": true }

取消排行榜参与资格时服务端自动将 profile_visibility 设为 false。

### 5.5 更新外观资料

预留 PUT /api/player/profile/cosmetics，字段为 titleId、backgroundId、nameplateId。服务端验证资源 ID，不接受任意文件路径或远程图片地址。

## 6. 排行榜接口调整

列表增加轻量字段：profileVisible、level、avatarId。关闭公开时返回匿名昵称、profileVisible=false、level=null。不在列表返回 B1 详情；用户点击后再请求详情，避免 N+1 请求。

## 7. Flutter 客户端计划

建议新增：

    lib/entity/Ranking/PlayerBriefProfile.dart
    lib/entity/Ranking/CheckinStatus.dart
    lib/entity/Ranking/CheckinResult.dart
    lib/service/CheckinService.dart
    lib/service/PlayerBriefProfileService.dart

现有 RankItem 增加 profileVisible 和 level。旧 JSON 缺少字段时默认关闭和空等级。

### 7.1 自动签到

在现有 App 初始化、首页或 System Hub 首次成功加载流程中接入。只触发一次；切换账号后重新判断；后台异步执行，不阻塞页面；保存当天本地处理状态以减少重复请求；本地状态不能代替服务端幂等；保留 mounted、离页和 Token 失效防护；不显示手动签到入口。

### 7.2 刷新设置

所有刷新入口增加“允许其他用户查看我的简要信息”。

重点检查：

    lib/widgets/RefreshDataDialog.dart
    lib/widgets/AdvancedRefreshDataDialog.dart
    lib/widgets/SyncScoreDialogs.dart
    lib/widgets/SyncFlowMixin.dart
    lib/page/SystemHubPage.dart
    lib/page/HomePage.dart

本地键建议为 CacheKeyConstant.profileVisibility，默认 false。关闭“参与排行榜”时自动关闭。服务端同步失败时明确提示。

### 7.3 排行榜点击和弹窗

修改 lib/page/RankingList/RatingRankListPage.dart：

    点击用户行
    → 请求 brief-profile
    → visible=false：提示“该用户关闭了信息展示”
    → visible=true：打开底部资料弹窗
    → 请求失败：提示“暂时无法加载玩家信息”

弹窗显示头像、昵称、等级、数据源、称号、背景、姓名框、使用天数、Best50/35/15 总 Rating、Best35 B1、Best15 B1 和 Rating 更新时间。详情只在点击时请求。

### 7.4 缓存

建议键为 brief_profile_数据源_用户ID，缓存有效期 10 分钟，记录 visible、profileRevision、fetchedAt。服务端返回隐藏、账号切换、资料更新或版本变化时清除。

## 8. 资源规则

头像复用现有 CommunityAvatar，只保存头像 ID。称号使用 titleId 映射客户端资源表，未知 ID 显示“未知称号”。背景首期使用客户端内置资源，未知 ID 回退默认背景。姓名框统一使用 nameplateId，兼容旧字段 plate。任一资源加载失败不能导致整个弹窗失败。

## 9. 部署步骤

部署前先备份数据库：

    备份数据库
    → 部署后端代码
    → 执行数据库迁移
    → 运行接口测试
    → 重启 PM2 server
    → 检查 PM2 日志
    → 检查 /api/health
    → 用测试账号验证自动签到
    → 验证资料公开和关闭状态

生产配置通过环境变量注入，例如 DATABASE_URL、JWT_SECRET、CHECKIN_TIMEZONE=Asia/Shanghai、PROFILE_ASSET_BASE_URL。健康接口只能证明进程存活，不能代替业务验收。

## 10. 测试计划

### 后端

覆盖首次自动签到 10 XP、连续第二天 12 XP、第七天及以后 22 XP、断签重置、同日重复启动、并发请求、服务端日期、跨数据源隔离、旧用户默认隐私、隐藏资料不返回详细字段、B1 稳定选择和敏感字段过滤。

### Flutter

覆盖新旧排行榜 JSON 解析、App 启动自动请求、已签到不重复提交、网络失败不显示成功经验、页面销毁后不 setState、隐藏资料提示、公开资料弹窗、所有刷新入口共用公开设置、账号切换不串签到状态。

### 真机

重点验证冷启动、热启动、跨日启动、账号切换、断网启动、资料弹窗和资源加载失败回退。静态分析不能代替真机验证。

## 11. 错误码

| 错误码 | 含义 | 客户端处理 |
|---|---|---|
| AUTH_REQUIRED | Token 失效 | 本次不签到，下次重试 |
| ACCOUNT_NOT_FOUND | 用户不存在 | 记录日志，不增加经验 |
| ALREADY_CHECKED_IN | 当日已签到 | 按成功状态处理 |
| PROFILE_HIDDEN | 用户关闭展示 | 显示关闭提示 |
| RATING_NOT_READY | Rating 未生成 | 显示暂无完整数据 |
| SERVER_BUSY | 服务端繁忙 | 不阻塞 App，下次启动重试 |

隐私关闭属于正常业务状态，不显示红色错误。

## 12. 兼容策略

老客户端访问新服务端时，不发送新字段、不要求自动签到，新增字段使用默认值，旧用户不自动公开。

新客户端访问旧服务端时，自动签到接口 404 不得阻塞 App；首页和排行榜继续工作；资料接口不可用时显示暂时无法加载；不因新接口不存在而阻塞成绩刷新。

## 13. 实施顺序

1. 确认认证和数据库结构。
2. 增加资料、签到和等级字段。
3. 执行迁移并为旧用户写默认值。
4. 实现签到状态和自动签到接口。
5. 实现幂等、事务和连续经验计算。
6. 实现公开资料接口和 B1 快照。
7. 扩展排行榜轻量字段。
8. Flutter 接入首次成功加载后的自动签到。
9. Flutter 接入刷新公开设置。
10. Flutter 实现排行榜资料弹窗。
11. 完成后端测试、Flutter 针对性测试和真机验证。
12. 备份数据库后部署生产环境。

## 14. 最终验收清单

- [ ] App 每日首次成功进入后自动签到。
- [ ] 用户不需要点击签到按钮。
- [ ] 同一天重复启动不会重复加经验。
- [ ] 连续签到经验更高，断签后重置。
- [ ] 服务端按北京时间判断日期。
- [ ] 等级不限制任何功能。
- [ ] 刷新数据时可选择是否公开资料。
- [ ] 默认关闭公开。
- [ ] 关闭排行榜参与时自动关闭资料展示。
- [ ] 点击公开用户可以打开资料弹窗。
- [ ] 点击关闭展示用户只看到提示。
- [ ] 弹窗显示头像、昵称、数据源、称号、背景和姓名框。
- [ ] 弹窗显示等级、使用天数和 Rating。
- [ ] 弹窗显示 Best35 B1 和 Best15 B1。
- [ ] 不泄露 QQ、Token 或其他隐私字段。
- [ ] 旧用户迁移后默认关闭资料展示。
- [ ] 签到接口具备幂等性。
- [ ] 生产凭据未写入代码和 Git。
- [ ] 数据库迁移前完成备份。
- [ ] PM2 重启后健康接口和业务接口均正常。

