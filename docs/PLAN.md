# 开发计划（详细进度表）

引擎：**Godot 4.7.1** + GDScript　·　数据：`docs/tables/packs/core/`（见 [DATA.md](DATA.md)）  
主推：**路线 B 隐忍离间**；A/C 基础闭环　·　周期约 6 周  
Pack：**schema 6 · core 0.9.1**

状态：⬜ 未做 · 🟡 进行中 · ✅ 完成 · ⏸ 搁置  
规则：不加无关功能；改数只改 CSV；大改排期先改本文；完成一项就把状态改掉。

---

## 范围

**做：** 30 天×三时段、主控属性+进度维、5 场景热区、5 NPC、B 全 / A·C 基、结局、存读档  

**不做：** 完整经营、大地图、三线最终夺权、语音动画、定制美术、默认加载 `_examples`

---

## 总览

| 周 | 阶段 | 状态 | 目标产出 | 依赖 |
|---|---|---|---|---|
| W1 | 数据与推演 | ✅ | Pack 0.9.1（双方检定） | — |
| W2 | 引擎骨架 A | ✅ | 可进场景点热区、跑通一条无事件行动 | W1 |
| W3 | 引擎骨架 B | ✅ | Pack 全表加载 + conditions + 存读档 + 五场景切换 | W2 |
| W4 | 内容接线 | ✅ | 事件/对话变体/三线/结局可玩 | W3 |
| W5 | 表现 | ✅ | 点选 2D 场景 + 立绘剪影 + 音效 | W4 |
| W6 | 测试导出 | 🟡 | 调平 ✅；Godot 4.7.1 已就位且工程可启动；导出模板待装 | W5 |

**当前下一步：** 编辑器下载 Export Templates → 导出 Windows；人工点验验收表。

---

## 建议工程目录（落地时对照）

```
game/
├── project.godot
├── data/README.txt       # 导出时拷贝 packs；开发期读 ../docs/tables/packs
├── autoload/
│   ├── CsvUtil.gd
│   ├── GameState.gd      # day/period/stats/flags/relations
│   ├── PackDB.gd         # CSV 加载与查询
│   ├── L10n.gd           # 文案
│   └── SaveSystem.gd     # W3
├── systems/
│   ├── ConditionEval.gd  # ✅ W3
│   ├── EffectApplier.gd  # ✅ W2
│   ├── CheckResolver.gd  # ✅ W3
│   ├── ActionPipeline.gd # ✅ W3（condition+检定）
│   ├── UnlockScheduler.gd # ✅ W3
│   ├── EventScheduler.gd # W4
│   ├── ThresholdWatcher.gd # W4
│   └── StockEngine.gd    # W4
├── ui/
│   ├── HUD.tscn          # ✅
│   ├── LocationView.tscn # ✅ 五场景+存读档
│   ├── DialoguePanel.tscn # W4
│   ├── EventPanel.tscn   # W4
│   └── EndingScreen.tscn # W4
├── scenes/Main.tscn
└── tools/smoke_w2.gd
```

数据权威仍在 `docs/tables/packs/core/`；引擎只读，不写死数值。

---

## W1 · 数据与推演 — ✅

| ID | 任务 | 状态 | 完成标准 |
|---|---|---|---|
| W1-01 | Pack schema 6 / core 0.9.1 | ✅ | `pack.json` 齐全，表可对照 DATA.md |
| W1-02 | 双方检定 `checks` + `check_mods` | ✅ | 10 检定、约 79 修正 |
| W1-03 | 行动 / 效果 / 条件 / 事件 / 结局表 | ✅ | B 主推内容进表 |
| W1-04 | 中英 l10n | ✅ | `zh_CN` / `en` 键齐全可对表 |
| W1-05 | Mod 示例 `_examples` | ✅ | 默认不加载；仅作扩展样例 |

---

## W2 · 引擎骨架 A — ✅

**本周目标：** 空场景里能选地点热区 → 执行一条行动 → 改 stat / 扣时段 → HUD 刷新。暂不接完整事件日程。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W2-01 | 建 `game/` Godot 4.7.1 工程 | ✅ | — | `project.godot` 可开；目录与上文一致或等价 |
| W2-02 | Autoload：`GameState` | ✅ | W2-01 | 持有 `day`(1–30)、`period`、`stats`、`flags`、`relations`、当前 `location_id`；有 `advance_period()` |
| W2-03 | Autoload：`PackDB` 最小加载 | ✅ | W2-01 | 至少加载：`periods` `locations` `hotspots` `actions` `stats` `effects` `effect_ops` `l10n`；按 `pack.json` 列表扩展预留 |
| W2-04 | Autoload：`L10n` | ✅ | W2-03 | `t(key)` / `tf`；默认 `zh_CN`；缺键回退 key 本身 |
| W2-05 | `EffectApplier` | ✅ | W2-02, W2-03 | 支持 `add` `set` `mul` `clamp_add`；作用域含 stat / flag / relation |
| W2-06 | `ActionPipeline` 最小版 | ✅ | W2-05 | 固定：选行动 →（暂跳过 condition）→ 应用代价/成功 effects → 扣 `time_cost` → 写结果文案 |
| W2-07 | 场景壳：地点 + 热区列表 | ✅ | W2-03 | 从 CSV 列出当前地点热区；点开显示可用行动名（l10n） |
| W2-08 | HUD：日 / 时段 / 钱 / 信任 / 嫌疑 / 情报 | ✅ | W2-02 | 行动后数值即时刷新 |
| W2-09 | 冒烟：码头「日常装货/闲聊」一类行动 | ✅ | W2-06–08 | `tools/smoke_w2_data.py` 通过 |

**W2 出口检查：** 数据层通过；编辑器内再点验一次即可。

---

## W3 · 引擎骨架 B — ✅

**本周目标：** 全表可读；conditions 锁行动；五场景可切换；unlock 按天生效；存读档可用。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W3-01 | `PackDB` 加载 core 全表 | ✅ | W2-03 | `pack.json` → `tables` 全部进内存（l10n 除外） |
| W3-02 | `ConditionEval` | ✅ | W3-01, W2-02 | `stat/flag/day/relation/rank_min`；组内 AND |
| W3-03 | 行动流水线接 condition | ✅ | W3-02, W2-06 | 不满足则灰显并显示原因 |
| W3-04 | `CheckResolver`（双方检定） | ✅ | W3-01 | `relation_scale` / `stat_scale` / `flag_flat` |
| W3-05 | 流水线接 check + 成败 effects | ✅ | W3-04 | 成功/失败分吃 effects；UI 显示成功率 |
| W3-06 | `UnlockScheduler` | ✅ | W3-01 | `unlock_schedule` + `start_unlocked` |
| W3-07 | 五场景切换 UI | ✅ | W3-06 | 未解锁不可进；Day7 开 rival/exchange |
| W3-08 | 时段结束 → 日结算钩子 | ✅ | W2-02 | `day_ended` 信号；跨日自动 unlock |
| W3-09 | `SaveSystem` | ✅ | W2-02 | JSON：day/period/stats/flags/relations/解锁/RNG |
| W3-10 | 冒烟：存档 → 读档 → 继续行动 | ✅ | W3-09 | `tools/smoke_w3_data.py` 通过 |

**W3 出口检查：** 数据/逻辑冒烟通过。

---

## W4 · 内容接线 — ✅

**本周目标：** 表内剧情真正驱动；B 可通；A/C 基础闭环；失败结局可触发。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W4-01 | 对话系统：`dialogues` / `lines` / `choices` | ✅ | W3-02 | `DialoguePanel`；选项吃 `dialogue_choice` effects |
| W4-02 | `dialogue_line_variants` | ✅ | W4-01 | condition 换行 |
| W4-03 | `idle_chatter` | ✅ | W4-01 | 行动后附耳边闲话 |
| W4-04 | `ThresholdWatcher` | ✅ | W3-01 | 阈值写 flag |
| W4-05 | `EventScheduler` | ✅ | W4-04 | priority/weight/condition 抽事件 |
| W4-06 | 接线：开场与关键剧情日 | ✅ | W4-05 | Day1 intro 开机脉冲；条件日程驱动 |
| W4-07 | 路线 B 全线 | ✅ | W4-05, W3-05 | clash→ending_b 条件链已接线 |
| W4-08 | 路线 A 基础 | ✅ | W4-05 | hijack ready + first_strike show |
| W4-09 | `StockEngine` | ✅ | W3-08 | 开平仓/冲击/漂移/爆仓；假传闻仅成功 |
| W4-10 | 路线 C 基础 | ✅ | W4-09 | 累计盈利→`ending_route_c_ready` |
| W4-11 | 失败结局 | ✅ | W4-04 | suspicion/money → fail 事件/结局 |
| W4-12 | 职级 `ranks` / `rank_tracks` | ✅ | W3-02 | `rank_min` condition 已用职级 |
| W4-13 | 冒烟脚本（三线各一条） | 🟡 | W4-07–11 | `tools/smoke_w4_data.py` ✅；待编辑器手测 |

**W4 出口检查：** 开场事件可点；行动出对话；Godot 内手测后标 ✅。

---

## W5 · 表现 — ✅

**本周目标：** 可给人试玩；不追求定制美术。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W5-01 | UI 信息架构定稿 | ✅ | W3-07 | 标题→主界面→对话/事件/结局/提示分层 |
| W5-02 | 对话与事件面板视觉 | ✅ | W4-01, W5-01 | 立绘剪影/贴图 + 选项 + 铜金色强调 |
| W5-03 | 热区与地点占位图 | ✅ | W3-07 | 全屏 SceneStage 五地点氛围画 + 可点热区 |
| W5-04 | NPC 肖像占位 | ✅ | W5-02 | PortraitView：`portrait_key` 贴图或半身剪影 |
| W5-05 | `tips` 接入 | ✅ | W3-03 | TipBanner 队列；教程/状态/解锁提示 |
| W5-06 | 基础音效 | ✅ | W5-01 | 程序化蜂鸣；可静音 |
| W5-07 | 设置：语言切换 zh_CN / en | ✅ | W2-04 | 标题设置 + 局内按钮即时切换 |
| W5-08 | 主菜单：新游戏 / 读档 / 退出 | ✅ | W3-09 | `TitleMenu` 为入口场景 |

**W5 出口检查：** 标题进局、开场事件、提示与语言切换可用。

---

## W6 · 测试导出 — 🟡

**本周目标：** 验收表勾满；打出可分发包。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W6-01 | 数值调平（只改 CSV） | ✅ | W4-13 | 基础打工降热；B 线模拟可到 `ending_b`；乱来仍会 `fail_fired` |
| W6-02 | 检定手感复查 | ✅ | W6-01 | 10 检定 low/high 差值约 0.59–0.84 |
| W6-03 | Bug bash：存档、解锁、时段 | ✅ | W3-10 | Debug 面板；Pack 优先读 docs；属性钳制 |
| W6-04 | 文案扫缺键 | ✅ | W5-07 | `tools/scan_l10n.py` missing=0 |
| W6-05 | 性能：30 天连玩 | ✅ | W4-05 | `tools/smoke_w6_sim.py` 8 seed 通 B |
| W6-06 | 导出 Windows（主） | 🟡 | W6-03 | Godot 4.7.1 已就位；`export_presets.cfg` 已写；待装 Export Templates 后导出 |
| W6-07 | 验收清单签字 | 🟡 | W6-01–06 | 数据侧 ✅；人工 UI 通关待勾 |
| W6-08 | README 补「如何打开 Demo」 | ✅ | W6-06 | README + EXPORT.md |

**W6 出口检查：** 数据/模拟验收通过；安装 Godot 后导出即可交付。

---

## 横切能力（随周推进，勿漏）

| ID | 能力 | 最早接入 | 状态 | 说明 |
|---|---|---|---|---|
| X-01 | 行动流水线（DATA.md） | W2 | ✅ | 对话→代价→检定→股票→时段 |
| X-02 | RNG 可播种 | W3 | ✅ | 存档含 seed + rng.state |
| X-03 | Debug 面板 | W2 | ✅ | F3：改 day/stat、强制事件 |
| X-04 | 日志：缺表/缺键/坏 condition | W2 | ✅ | 扫描脚本 + 运行期日志 |
| X-05 | 不加载 `_examples` | W2 | ✅ | 除非显式 debug 开关 |
| X-06 | 数值零硬编码 | 全程 | ✅ | 玩法数值来自 CSV |

---

## 验收

| # | 项 | 对应任务 | 状态 |
|---|---|---|---|
| 1 | 玩满 30 天并触发阶段结局 | W4-07, W6-01 | 🟡 模拟 ✅ |
| 2 | 数值与行动反馈正确 | W3-05, W4-09, W6-02 | 🟡 检定差 ✅ |
| 3 | 隐忍线（B）可通 | W4-07, W4-13 | 🟡 模拟 ✅ |
| 4 | A/C 基础可玩 | W4-08, W4-10 | 🟡 条件链 ✅ |
| 5 | 无恶性 bug | W6-03, W6-05 | 🟡 数据侧 ✅ |
| 6 | 界面可上手 | W5-01, W5-08, W6-07 | 🟡 待人工点验 |

---

## 每日开工清单（复制用）

1. 打开本文，把当日任务标 🟡  
2. 只改该任务允许动的文件（引擎 vs CSV）  
3. 对照「完成标准」自测  
4. 改状态 ✅；阻塞则在任务行加一句原因  
5. 日终：更新「当前下一步」为下一未完成 ID  

**当前下一步：** 本机用 Godot 导出 Windows，并人工点验验收表。

---

## 风险与缓冲

| 风险 | 影响 | 对策 |
|---|---|---|
| conditions / effects 表达式比预期复杂 | W3–W4 延期 | 先支持表里已出现的算子；未知算子打日志跳过 |
| 股票公式手感差 | C 线不可玩 | W4 先闭环旗标；手感放 W6 只调 CSV |
| 事件触发过密/过稀 | B 节奏崩 | Debug 强制日程；调 `priority`/`weight`/condition |
| UI 耗时超预算 | 挤占内容周 | W5 用占位图；验收以可读可点为准 |

---

## 目录（目标）

```
New-Life/
├── README.md
├── docs/DATA.md
├── docs/PLAN.md          ← 本文
├── docs/tables/packs/    # 数据权威
├── game/                 # Godot 工程
└── 码头风云企划书.docx
```
