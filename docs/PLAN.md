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
| W2 | 引擎骨架 A | ⬜ | 可进场景点热区、跑通一条无事件行动 | W1 |
| W3 | 引擎骨架 B | ⬜ | Pack 全表加载 + conditions + 存读档 + 五场景切换 | W2 |
| W4 | 内容接线 | ⬜ | 事件/对话变体/三线/结局可玩 | W3 |
| W5 | 表现 | ⬜ | 可读 UI、占位美术、基础音效 | W4 |
| W6 | 测试导出 | ⬜ | 调平、验收勾满、可导出包 | W5 |

**当前下一步：** `W2-01` 建 `game/` Godot 工程。

---

## 建议工程目录（落地时对照）

```
game/
├── project.godot
├── data/                 # 运行时拷贝或指向 docs/tables/packs（二选一，文档写死）
├── autoload/
│   ├── GameState.gd      # day/period/stats/flags/relations
│   ├── PackDB.gd         # CSV 加载与查询
│   ├── L10n.gd           # 文案
│   └── SaveSystem.gd
├── systems/
│   ├── ConditionEval.gd
│   ├── EffectApplier.gd
│   ├── CheckResolver.gd  # 双方检定
│   ├── ActionPipeline.gd # DATA.md 流水线
│   ├── EventScheduler.gd
│   ├── ThresholdWatcher.gd
│   ├── UnlockScheduler.gd
│   └── StockEngine.gd
├── ui/
│   ├── HUD.tscn
│   ├── DialoguePanel.tscn
│   ├── EventPanel.tscn
│   └── EndingScreen.tscn
└── scenes/
    ├── Main.tscn
    ├── LocationView.tscn
    └── HotspotButton.tscn
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

## W2 · 引擎骨架 A — ⬜

**本周目标：** 空场景里能选地点热区 → 执行一条行动 → 改 stat / 扣时段 → HUD 刷新。暂不接完整事件日程。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W2-01 | 建 `game/` Godot 4.7.1 工程 | ⬜ | — | `project.godot` 可开；目录与上文一致或等价 |
| W2-02 | Autoload：`GameState` | ⬜ | W2-01 | 持有 `day`(1–30)、`period`、`stats`、`flags`、`relations`、当前 `location_id`；有 `advance_period()` |
| W2-03 | Autoload：`PackDB` 最小加载 | ⬜ | W2-01 | 至少加载：`periods` `locations` `hotspots` `actions` `stats` `effects` `effect_ops` `l10n`；按 `pack.json` 列表扩展预留 |
| W2-04 | Autoload：`L10n` | ⬜ | W2-03 | `tr_key(key)`；默认 `zh_CN`；缺键回退 key 本身 |
| W2-05 | `EffectApplier` | ⬜ | W2-02, W2-03 | 支持 `add` `set` `mul` `clamp_add`；作用域含 stat / flag / relation |
| W2-06 | `ActionPipeline` 最小版 | ⬜ | W2-05 | 固定：选行动 →（暂跳过 condition）→ 应用代价/成功 effects → 扣 `time_cost` → 写结果文案 |
| W2-07 | 场景壳：地点 + 热区列表 | ⬜ | W2-03 | 从 CSV 列出当前地点热区；点开显示可用行动名（l10n） |
| W2-08 | HUD：日 / 时段 / 钱 / 信任 / 嫌疑 / 情报 | ⬜ | W2-02 | 行动后数值即时刷新 |
| W2-09 | 冒烟：码头「日常装货/闲聊」一类行动 | ⬜ | W2-06–08 | 手动点 3 次，时段推进正确，钱/属性有变化 |

**W2 出口检查：** 不崩溃；HUD 与 state 一致；数值来自 CSV 而非脚本常量。

---

## W3 · 引擎骨架 B — ⬜

**本周目标：** 全表可读；conditions 锁行动；五场景可切换；unlock 按天生效；存读档可用。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W3-01 | `PackDB` 加载 core 全表 | ⬜ | W2-03 | `pack.json` → `tables` 全部进内存；未知列容忍或打日志 |
| W3-02 | `ConditionEval` | ⬜ | W3-01, W2-02 | 解析 `conditions.csv`；行动/热区/对话选项可过滤；测 5 条典型条件 |
| W3-03 | 行动流水线接 condition | ⬜ | W3-02, W2-06 | 不满足则灰显或隐藏，并有原因（可用 tip key） |
| W3-04 | `CheckResolver`（双方检定） | ⬜ | W3-01 | 实现 DATA.md 公式；`relation_scale` / `stat_scale` / `flag_flat`；结果 clamp |
| W3-05 | 流水线接 check + 成败 effects | ⬜ | W3-04 | 有 `check_id` 的行动走检定；成功/失败各吃对应 effects |
| W3-06 | `UnlockScheduler` | ⬜ | W3-01 | 按 `unlock_schedule` + day 解锁 location/hotspot/flag；与 condition 叠加 |
| W3-07 | 五场景切换 UI | ⬜ | W3-06 | dock / company / home / rival / exchange；未解锁不可进 |
| W3-08 | 时段结束 → 日结算钩子 | ⬜ | W2-02 | evening 结束后 `day++`、period=morning；预留 `on_day_end`（股票用） |
| W3-09 | `SaveSystem` | ⬜ | W2-02 | JSON 存：day/period/stats/flags/relations/解锁态/RNG 种子；读档恢复 HUD |
| W3-10 | 冒烟：存档 → 读档 → 继续行动 | ⬜ | W3-09 | 数值与解锁一致 |

**W3 出口检查：** 可切换五场景；锁区正确；检定成功率随关系变化；存读档无损。

---

## W4 · 内容接线 — ⬜

**本周目标：** 表内剧情真正驱动；B 可通；A/C 基础闭环；失败结局可触发。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W4-01 | 对话系统：`dialogues` / `lines` / `choices` | ⬜ | W3-02 | 行动可弹出对话；选项再跑 condition；选完继续流水线 |
| W4-02 | `dialogue_line_variants` | ⬜ | W4-01 | 按 condition 换行；无匹配用默认行 |
| W4-03 | `idle_chatter` | ⬜ | W4-01 | 行动后或场景内可刷一句闲聊（可关） |
| W4-04 | `ThresholdWatcher` | ⬜ | W3-01 | 关系/属性阈值写 flag（如 `tension_high` `suspicion_*`） |
| W4-05 | `EventScheduler` | ⬜ | W4-04 | 按时段/天/priority/weight/condition 抽事件；`event_choices` 可选 |
| W4-06 | 接线：开场与关键剧情日 | ⬜ | W4-05 | 至少：`ev_day1_intro` `ev_day5_*` `ev_day7_choice` 能触发 |
| W4-07 | 路线 B 全线 | ⬜ | W4-05, W3-05 | 假消息/晚晴/公开对立等；`ending_route_b_ready` + `show` → `ending_b` |
| W4-08 | 路线 A 基础 | ⬜ | W4-05 | 通洋相关行动+`ev_a_first_strike`；ready/show → `ending_a` |
| W4-09 | `StockEngine` | ⬜ | W3-08 | 实现 `stock_rules`：开平仓、传闻冲击、日终漂移、爆仓检查；假传闻仅成功执行 `rule_rumor_fake` |
| W4-10 | 路线 C 基础 | ⬜ | W4-09 | 盈利达标 → `ending_route_c_ready`；事件写 `show` → `ending_c` |
| W4-11 | 失败结局 | ⬜ | W4-04 | `ending_fail_fired` / `ending_fail_broke` 可测触发 |
| W4-12 | 职级 `ranks` / `rank_tracks` | ⬜ | W3-02 | 信任档位影响解锁/文案（与 condition 一致） |
| W4-13 | 冒烟脚本（三线各一条） | ⬜ | W4-07–11 | 文档或 debug 命令：B 通、A 通、C 通、失败各 1 次 |

**W4 出口检查：** 不靠改脚本能靠 CSV 改剧情；三线结局与两种失败可复现。

---

## W5 · 表现 — ⬜

**本周目标：** 可给人试玩；不追求定制美术。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W5-01 | UI 信息架构定稿 | ⬜ | W3-07 | HUD / 场景 / 对话 / 事件 / 结局层级清晰，移动与桌面都可读 |
| W5-02 | 对话与事件面板视觉 | ⬜ | W4-01, W5-01 | 立绘位（可占位色块）+ 选项列表 + 结果反馈 |
| W5-03 | 热区与地点占位图 | ⬜ | W3-07 | 5 地点可区分；热区可点区域明确 |
| W5-04 | NPC 肖像占位 | ⬜ | W5-02 | `portrait_key` 能映射到资源；缺省有默认图 |
| W5-05 | `tips` 接入 | ⬜ | W3-03 | 新手提示 / 锁行动原因 |
| W5-06 | 基础音效 | ⬜ | W5-01 | 点击、成功/失败检定、时段切换、结局（可静音） |
| W5-07 | 设置：语言切换 zh_CN / en | ⬜ | W2-04 | 即时换文案，无需重启 |
| W5-08 | 主菜单：新游戏 / 读档 / 退出 | ⬜ | W3-09 | 完整进出流程 |

**W5 出口检查：** 陌生人 5 分钟内知道「看哪、点哪、一天怎么过」。

---

## W6 · 测试导出 — ⬜

**本周目标：** 验收表勾满；打出可分发包。

| ID | 任务 | 状态 | 依赖 | 完成标准 |
|---|---|---|---|---|
| W6-01 | 数值调平（只改 CSV） | ⬜ | W4-13 | B 主线约 25–30 天可通；嫌疑/破产有风险但不无解 |
| W6-02 | 检定手感复查 | ⬜ | W6-01 | 关键 10 检定在关系高低两端差异可感知 |
| W6-03 | Bug bash：存档、解锁、时段 | ⬜ | W3-10 | 无卡死、无软锁、无负时段 |
| W6-04 | 文案扫缺键 | ⬜ | W5-07 | zh/en 无大量 raw key；语气统一 |
| W6-05 | 性能：30 天连玩 | ⬜ | W4-05 | 无泄漏；切场景流畅 |
| W6-06 | 导出 Windows（主） | ⬜ | W6-03 | `builds/` 可运行；`.gitignore` 已忽略构建物 |
| W6-07 | 验收清单签字 | ⬜ | W6-01–06 | 下方验收表全部 ✅ |
| W6-08 | README 补「如何打开 Demo」 | ⬜ | W6-06 | 引擎版本、运行/导出步骤各 3 行内 |

**W6 出口检查：** Demo 可交付试玩。

---

## 横切能力（随周推进，勿漏）

| ID | 能力 | 最早接入 | 状态 | 说明 |
|---|---|---|---|---|
| X-01 | 行动流水线（DATA.md） | W2 | ⬜ | W2 最小 → W3 检定 → W4 对话/股票 |
| X-02 | RNG 可播种 | W3 | ⬜ | 存档含 seed；检定/事件可复现 |
| X-03 | Debug 面板 | W2 | ⬜ | 改 day/stat/flag、强制事件、打印 chance |
| X-04 | 日志：缺表/缺键/坏 condition | W2 | ⬜ | 开发期必须看得见 |
| X-05 | 不加载 `_examples` | W2 | ✅（约定） | 除非显式 debug 开关 |
| X-06 | 数值零硬编码 | 全程 | ⬜ | Code review 对照：改玩法只动 CSV |

---

## 验收

| # | 项 | 对应任务 | 状态 |
|---|---|---|---|
| 1 | 玩满 30 天并触发阶段结局 | W4-07, W6-01 | ⬜ |
| 2 | 数值与行动反馈正确 | W3-05, W4-09, W6-02 | ⬜ |
| 3 | 隐忍线（B）可通 | W4-07, W4-13 | ⬜ |
| 4 | A/C 基础可玩 | W4-08, W4-10 | ⬜ |
| 5 | 无恶性 bug | W6-03, W6-05 | ⬜ |
| 6 | 界面可上手 | W5-01, W5-08, W6-07 | ⬜ |

---

## 每日开工清单（复制用）

1. 打开本文，把当日任务标 🟡  
2. 只改该任务允许动的文件（引擎 vs CSV）  
3. 对照「完成标准」自测  
4. 改状态 ✅；阻塞则在任务行加一句原因  
5. 日终：更新「当前下一步」为下一未完成 ID  

**当前下一步：** `W2-01` 建 `game/` Godot 工程。

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
├── game/                 # Godot（待建）
└── 码头风云企划书.docx
```
