# Effect 词汇表（白名单）

> 行动 / 事件 / 对话选项 / 日 tick **共用**本表。  
> **禁止**文档或 Mod 私造未列出的 `op`。扩词须改本文件并升版本。

相关：[`数据库架构.md`](数据库架构.md) · [`存档结构.md`](存档结构.md)

---

## 1. 通用形状

```yaml
- op: <动词>
  # 下列键按 op 选用，勿混用无文档字段
  key: stat_* | flag 相关见各 op
  value: number | bool | string
  min: number          # 仅 add_range
  max: number
  edge: { from: char_*, to: char_* }
  meter: <meter_id>
  id: <clue_id|item_id|...>
  reason: string       # 可选，调试用
```

一次 effect 数组 **顺序执行**；中途失败策略：Demo 建议 **跳过非法条并打日志**，不回滚整次（可后改事务）。

---

## 2. 白名单 · `op`

### 2.1 数值

| op | 目标 | 必填 | 语义 |
|---|---|---|---|
| `add` | `key: stat_*` | key, value | 加（可为负） |
| `set` | `key: stat_*` | key, value | 覆盖 |
| `add_range` | `key: stat_*` | key, min, max | 均匀或表内随机取整 |

例：

```yaml
- { op: add, key: stat_intel, value: 15 }
- { op: add_range, key: stat_money, min: 2, max: 3 }
- { op: add, key: stat_credit_bank, value: 5 }
```

### 2.2 交情边

| op | 必填 | 语义 |
|---|---|---|
| `add` + `edge` | edge, key∈{score,suspicion,trust,fear}, value | 改边字段；score 改后重算 tier |
| `set` + `edge` | 同上 | 覆盖 |

金融扩展（建议）：

| op | 必填 | 语义 |
|---|---|---|
| `set` + `edge` | edge, key=`debt`, value | 记人情债/口头账 |
| `set` + `edge` | edge, key=`leverage`, value | 记把柄/担保/卡脖子点 |

`trust` / `fear`：Demo **必须用整数档** `0=低 1=中 2=高 3=极高`，`add` 按档步进。  
`suspicion`：同上，另可到 `4=杀意`（触发 F005）。日末若钱→林 suspicion ≥3，自动 −1。  
**禁止**在 require/effect 里写 `high` / `mid` / `extreme` 等字符串。

```yaml
- { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 10 }
- { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: 1 }
- { op: set, edge: {from: char_wang_pangzi, to: char_lin_ruisheng}, key: debt, value: 酒情未还 }
- { edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, op: ">=", value: 2 }  # R007
```
### 2.3 Meter

| op | 必填 | 语义 |
|---|---|---|
| `add` + `meter` | meter, value | 玩法计量加减 |
| `set` + `meter` | meter, value | 覆盖 |

合法 `meter_id` 见 [`旗标与命名.md`](旗标与命名.md)。

```yaml
- { op: add, meter: father_son, value: -25 }
```

### 2.4 旗标

| op | 必填 | 语义 |
|---|---|---|
| `set_flag` | key=`flag_*`\|`route_*`, value | bool 或短枚举 |
| `clear_flag` | key | 删除/置 false |

```yaml
- { op: set_flag, key: route_endure, value: true }
```

### 2.5 线索 / 信物

| op | 必填 | 语义 |
|---|---|---|
| `unlock_clue` | id=`clue_*` | 可选 `quality: full\|partial\|physical` |
| `revoke_clue` | id | 少用 |
| `grant_item` | id=`item_*` | 信物/把柄入包 |
| `revoke_item` | id | |

```yaml
- { op: unlock_clue, id: clue_special_goods, quality: partial }
- { op: grant_item, id: item_qing_letter }
```

### 2.6 债务 / 金融服务

| op | 必填 | 语义 |
|---|---|---|
| `open_debt` | `service_id`, `creditor`, `principal` | 建立债务实例 |
| `repay_debt` | `debt_id`, `value` | 偿还部分/全部债务 |
| `set_debt_status` | `debt_id`, `value` | 改为 `active` / `overdue` / `cleared` |

```yaml
- { op: open_debt, service_id: svc_bank_loan_short, creditor: org_bank, principal: 15 }
- { op: repay_debt, debt_id: debt_bank_short_001, value: 5 }
- { op: set_debt_status, debt_id: debt_bank_short_001, value: overdue }
```

适用：

- 票号短借
- 续借展期
- 私下借账
- 洋行预支（若后续扩）

### 2.7 职级 / 恩怨

| op | 必填 | 语义 |
|---|---|---|
| `set_rank` | `value`∈{apprentice,waichang,paojie,houtang} | 写 `run_meta.player_rank`；触发升职演出 |
| `unlock_grudge` | `id`=`grudge_*` | 埋债入 `run_grudge`；已存在则保持 open 并可加深 |
| `resolve_grudge` | `id`, `mode`∈{punish,forgive} | 兑现；改 status |
| `expire_grudge` | `id` | 过期未兑 |

```yaml
- { op: set_rank, value: waichang }
- { op: unlock_grudge, id: grudge_zian_fiancee }
- { op: resolve_grudge, id: grudge_onlooker, mode: punish }
```

合法 `grudge_*` 见 [`../05_关系档案/恩怨账与清算.md`](../05_关系档案/恩怨账与清算.md)。

### 2.8 朝账

| op | 必填 | 语义 |
|---|---|---|
| `assign_weekly_tasks` | `ids: [task_*]` | 写入 `run_meeting.weekly_tasks` |
| `add_meeting_report` | `value` | 加本周 `report_score`（封顶 100） |
| `set_meeting_tier` | `value`∈{listen,report,decide} | 写 `run_meeting.attendance_tier` |
| `init_council_queue` | `ids: [char_*]` | 生成本局 ④ 段发言顺序 |
| `record_council_speech` | `char`, `spoke`, `topic_key?`, `stance?`, `mode?` | 记发言/沉默/附议入 `council_log` |
| `endorse_last_council` | （无） | decide：附议上一发言者 stance，`policy_draft+2`，trust+1 |
| `add_policy_draft` | `key`, `value` | 累加 `policy_draft`，供 ⑤ 定调 |
| `set_meeting_segment` | `value`∈{rollcall,report,ceremony,council,policy,tasks} | 仅发 `meeting_segment_changed`；表现层议场切段 |

```yaml
- { op: assign_weekly_tasks, ids: [task_tidy_manifest, task_front_duty] }
- { op: add_meeting_report, value: 8 }
- { op: set_meeting_tier, value: report }
- { op: set_meeting_segment, value: council }
- { op: init_council_queue, ids: [char_zhou_guanshi, char_wang_pangzi] }
- { op: record_council_speech, char: char_lin_ruisheng, spoke: true, stance: bright_steady, mode: speak }
- { op: add_policy_draft, key: bright_steady, value: 2 }
```

规则：[`../17_朝账系统/朝账系统规则.md`](../17_朝账系统/朝账系统规则.md) · 建言：[`../17_朝账系统/诸人建言.md`](../17_朝账系统/诸人建言.md) · 议场：[`../17_朝账系统/朝账议场演出合同.md`](../17_朝账系统/朝账议场演出合同.md)。

### 2.8b 序位战

| op | 必填 | 语义 |
|---|---|---|
| `init_ladder_pool` | `pool_id` | 换池并生成竞争者 `entries` |
| `add_ladder_score` | `char`, `value` | 池内加分 |
| `set_ladder_slots` | `value` | 本朝账可升名额 |
| `bias_ladder_npc` | `char`, `value` | 剧情周 NPC 偏置（如子安/孙六） |

```yaml
- { op: init_ladder_pool, pool_id: pool_apprentice }
- { op: add_ladder_score, char: char_lin_ruisheng, value: 8 }
- { op: bias_ladder_npc, char: char_qian_zian, value: 12 }
```

规则：[`../13_职级档案/职级竞争与排名.md`](../13_职级档案/职级竞争与排名.md)。

### 2.9 流程控制（慎用）

| op | 必填 | 语义 |
|---|---|---|
| `set_temp` | key, value | 仅当前时段有效，不进长期存档 |
| `queue_event` | id=`E*|M*|R*|F*` | 插入事件队列 |
| `goto_dialog` | id=`dialog_*` | 跳转对话节点 |
| `mod_success` | value | 临时修正成功率（如 −0.30） |
| `end_run` | reason（可选） | **立即结束本局**（F003/F005 等）；可先播对白再结算 |
| `menu` | options | **行动内分支**（如 `act_11` 钱庄）；子项可含 require / effects |

`menu` 形状（设计期；实现可展平为对话 choices）：

```yaml
- op: menu
  options:
    loan:
      label: 短借
      require: [{ key: stat_money, op: ">=", value: 10 }]
      effects:
        - { op: add, key: stat_money, value: 15 }
        - { op: set_flag, key: flag_bank_loan_active, value: true }
      goto_dialog: dialog_act_11_loan
    remit:
      label: 汇兑
      require: [{ key: stat_money, op: ">=", value: 20 }]
      effects:
        - { op: add, key: stat_money, value: -5 }
      goto_dialog: dialog_act_11_remit
```

```yaml
- { op: set_temp, key: risk_tier, value: high }
- { op: queue_event, id: R007 }
- { op: end_run, reason: fired }
- { op: goto_dialog, id: dialog_act_01_outro_tight }
```

---

## 3. 条件 `require`（非 effect，但同契约）

用于事件触发、选项解锁、行动前置：

| 形状 | 例 |
|---|---|
| 属性 | `{ key: stat_intel, op: ">=", value: 35 }` |
| 边档 | `{ edge: {from,to}, tier_in: [相善, 厚交] }` |
| 边分 | `{ edge: {from,to}, key: score, op: ">=", value: 40 }` |
| 边修正 | `{ edge: {from,to}, key: suspicion, op: ">=", value: 2 }` |
| meter | `{ meter: pursuit, op: ">=", value: 40 }` |
| 线索 | `{ clue: clue_light_crate, owned: true }` |
| 旗标 | `{ flag: route_foreign, value: true }` |
| 信物 | `{ item: item_qing_letter, owned: true }` |
| 地点 | `{ loc: loc_03 }` |
| 时段 | `{ slot: evening }` 或 `{ slot_in: [noon, afternoon, evening] }` |
| 职级 | `{ rank: waichang }` 或 `{ rank_in: [waichang, paojie] }` |
| 恩怨 | `{ grudge: grudge_zian_fiancee, status: open }`；`status: absent` 表示未埋 |
| 复合 | 数组内 AND；`goto_dialog_by_condition` 按序首匹配 |

合法比较：`>=` `<=` `>` `<` `==` `!=`。

行动完成口风（非 effect，引擎钩子）：

```yaml
goto_dialog_by_condition:
  - require: [{ key: stat_money, op: "<", value: 20 }]
    id: dialog_act_03_outro_tight
  - require: [{ key: stat_money, op: ">=", value: 50 }]
    id: dialog_act_03_outro_well
  - default: dialog_act_03_outro_default
```

---

## 4. 禁止

- `attitude.favor` / 「好感度+N」自然语言当逻辑  
- 未登记的 `meter_*` / `flag_*`  
- 疑心/信任用 `high`/`extreme` 等字符串（必须 0–3）  
- 在 effect 里直接改定义库字段  
- 一次选项写死 UI 长文案当 op（文案走 `loc_key`）
- 用 `run_debt` 记录人情债（人情债优先写 `run_edge.debt`）

---

## 5. 版本

| 版本 | 内容 |
|---|---|
| **v0.1** | 初版白名单：stat / edge / meter / flag / clue / item / temp / queue / dialog |
| **v0.2** | 增加 `menu`；行动口风 `goto_dialog_by_condition`；金钱旗标样例 |
| **v0.3** | require 补 `slot` / `slot_in`；随机事件 loc 前置 |
| **v0.4** | 增加 `credit_*`、`open_debt/repay_debt/set_debt_status`；说明 edge.debt/leverage 的金融用法 |
| **v1.0** | 增加 `set_rank` / `unlock_grudge` / `resolve_grudge` / `expire_grudge`；require 补 rank / grudge |
