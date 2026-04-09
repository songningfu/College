# College 开发日志

> **文档定位**：记录项目的重要系统调整、阶段性里程碑与文档体系变更。  
> **使用原则**：只记录会影响整体判断的更新，不记录零碎日常改动。  
> **最后整理**：2026-04-08

---

## 2026-04-09 - Day 1 上午手牌恢复验证通过

### 验证结果
- 通过 `scenes/debug/test_runner.tscn` + `scripts/debug/test_runner.gd` 重新验证 Day 1 首日流程
- 已确认 `抵达 208` 事件之后会正常回到上午发牌，不再直接从早晨事件链跳到晚上
- 已确认 Day 1 上午可正常出现 5 张首日手牌：新生报到 / 熟悉宿舍楼 / 逛校园 / 食堂吃饭 / 宿舍休息
- 已确认默认入口仍为 `project.godot` → `res://scenes/ui/ui_test_v2.tscn`
- 已确认 `ui_test_v2.tscn` 内可拖动测试面板仍保留

### 调试链修正
- `scripts/debug/test_runner.gd` 已补足无选项事件后的自动推进，避免调试跑图卡在单段事件上
- 当前回归验证入口口径统一为 `scenes/debug/test_runner.tscn`，不再写成旧的 `scenes/test_scene.tscn`

### 当前仍待继续验证的问题
- V2 默认入口中的中午骰子 → 后续事件分支，还需继续实机核对
- 晚间骰子 → good / bad 收束分支，还需继续实机核对
- Day 1 部分文本仍需继续清理“旁白 / 对白”边界
- Phone / Summary 虽已接入 Day 1 结果引用，但还需继续检查是否完全贴合当天实际发生内容

---

## 2026-04-08 - Day 1 定制流程并入 V2 主链

### Day 1 演出接入
- Day 1 开场已改为黑屏居中文字演出，再进入 208 宿舍报到流程
- 208 宿舍口径固定为：林逸枫 / 周文 / 陈向星 / 沈砚麒
- 中午事件顺序已明确写入事件链：先林逸枫，再陈向星，再进入陈向星父亲提问与后续判定
- 夜间已补入全员到齐后的 208 夜谈与骰子后续分支

### 事件与选择
- `EventSystem` 已补入 Day 1 的顺序事件、绑定事件与 Day 1 夜间收束分支
- `DayManager` 已接管事件选项结算，选择结果会落到属性 / 资源 / 好感，并进入日总结统计
- `ui_test_v2.gd` 已从“仅展示选项”改为把事件选择回传 core，再继续后续事件

### Day 1 专属适配
- `CardSystem` 已加入 Day 1 专属手牌池与推荐卡口径
- `StoryLayer` 已支持黑屏居中文字、Day 1 主角测试立绘出场与 Day 1 骰子演出切入
- `PhoneLayer` / `DaySummaryLayer` 已开始引用 Day 1 当天事件结果生成首日反馈

### 当前已知问题
- Day 1 早晨时段仍存在被高优先级事件链过度占用的情况，实际运行中可能直接跳过白天手牌阶段
- 部分事件文本虽然挂了说话人名字，但正文仍是偏旁白写法，说明“对白/旁白分离”还没完全收口
- 黑屏开场效果当前表现稳定，是 Day 1 演出里最先跑通的一段

---

## 2026-04-08 - V2 UI 升为默认入口

### 入口与主链
- `project.godot` 默认入口切换到 `res://scenes/ui/ui_test_v2.tscn`
- `scenes/ui/ui_test_v2.gd` 从手动演示脚本升级为当前 V2 UI 主控 / 适配层
- 启动后会重置 run、注册 Demo NPC，并由 `DayManager` 信号驱动 Today / Story / Phone / Summary

### UI 接线
- TodayView 已接真实状态、时段、AP 与手牌数据
- StoryLayer 已接事件展示、选项展示与简化演出适配
- DaySummaryLayer 已接 `summary` 适配结果
- PhoneLayer 已接联系人、未读与回复原型流程
- 测试面板继续保留，并支持拖动

### 骰子与交互
- DiceLayer 从文本点数升级为 1~6 骰子素材显示
- StoryLayer 支持空格 / 回车 / 鼠标左键推进
- PhoneLayer 支持 `Esc` 返回 / 关闭，以及点击空白遮罩关闭

### 回退与验证
- 旧 `ui_test_root` 保留为冻结回退路径
- `scenes/test_scene.tscn` + `scripts/debug/test_runner.gd` 继续保留为 21 天自动测试入口
- 已确认默认 V2 入口与旧测试链可并存运行

### 清理与收束
- 移除旧 `scenes/debug/dice_test_runner.tscn` + `scripts/debug/dice_test_runner.gd`
- 骰子层联调统一收口到 `ui_test_v2.tscn` 内的 `TestControls`
- `scenes/main.tscn` 与 `ui_test_root` 继续保留为旧包装 / 冻结回退路径

---

## 2026-04-07 - 系统修订补丁 v1 应用完成

### 核心系统
- 重写 `game_manager.gd`：Phase 枚举化，去掉旧限制写法
- 重写 `day_manager.gd`：接入新发牌流程、Day 2 推荐系统与军训调整
- 重写 `test_runner.gd`：改为 21 天自动测试与数值验证输出

### 数值调整
- 每日精力回复：`8 → 7`
- 军训精力消耗：`3 → 4`
- 关系衰减冷却：`3 天 → 5 天`
- 新增关系免疫期：`7 天`
- 顾遥初始好感：`20 → 30`
- 社团活动卡：随机池 → 保底卡

### 文档体系
- 建立 `docs/` 主结构
- 重写根目录 `README.md`
- 拆分出项目概览、程序、玩法、剧本、UI、计划等主文档
- 将旧日志与规则书降级为历史 / 参考材料

### 当时测试状态
- 自动测试场景：`scenes/test_scene.tscn`
- 重点验证项：
  1. 军训期（Day 3-9）精力压力是否成立
  2. Day 20 顾遥好感是否稳定接近目标区间
  3. 每时段手牌是否保有实质选择差异

---

## 2026-04-06 及之前 - 核心系统初版实现

### 系统架构
- 搭建 6 大核心系统：`GameManager`、`AttributeSystem`、`RelationshipSystem`、`CardSystem`、`EventSystem`、`DayManager`
- 采用 Autoload 单例模式
- 建立 Phase 状态机

### 卡牌系统
- 定义 25+ 张行动卡
- 实现随机发牌与保底机制
- 实现按天数 / 好感度解锁内容

### 事件系统
- 实现优先级仲裁（强制事件优先）
- 实现顺延机制
- 添加 Day 14 社团招新等关键节点

### UI 骨架
- 搭起顶部状态栏 + 中景舞台区 + 时段区 + 底部手牌区
- 做出事件层、骰子层、手机层、日结算层原型
- 但当前版本不能再写成“已完整接通正式主链”

### 文档基础
- 完成立项底稿
- 完成剧本共创稿
- 完成 UI 素材规格初稿
- 保留核心循环系统规则书作为参考输入稿

