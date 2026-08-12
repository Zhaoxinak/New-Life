# 对话 · M003 升外场朝账

> 入口：`dialog_m003_start` · 事件 [`../07_事件档案/朝账/M003_升外场朝账.md`](../07_事件档案/朝账/M003_升外场朝账.md)  
> 内嵌：E020 / E020B / E020C（③ 仪典）。④ 玩家首次可选建言。  
> 共用池：[`DIALOG_MEETING_COUNCIL.md`](DIALOG_MEETING_COUNCIL.md)

---

## 节点图

```
dialog_m003_start
  → dialog_m003_enter_hall       # 首次进堂
  → dialog_m003_report_choice    # ② 汇报口径分支
  → dialog_m003_report_a / _b / _c
  → [mutex] dialog_e020_start | dialog_e020b_start | dialog_e020c_start
  → dialog_council_zhou_order    # ④ 周管事建言
  → dialog_council_wang_front    # ④ 王胖子建言
  → dialog_meeting_council_player_pick  # ④ 玩家：建言 / 不言
  → dialog_m003_policy           # ⑤ 定调
  → dialog_m003_tasks            # ⑥ 外场差事
  → dialog_m003_close
```

---

## Nodes（摘要）

### `dialog_m003_start`

```yaml
speaker: narrator
text_zh: |
  这一回，周管事掀开门帘：「进去。这周轮到你报。」
next: dialog_m003_enter_hall
```

### `dialog_m003_report_choice`

```yaml
speaker: char_qian_demao
text_zh: |
  林瑞生，你这周差事办得怎样？自己说。
choices:
  - id: honest
    label: 如实报账，不夸大
    next: dialog_m003_report_a
  - id: polish
    label: 报喜不报忧
    next: dialog_m003_report_b
  - id: hold
    label: 留一手，只说东家该听的
    next: dialog_m003_report_c
```

### `dialog_m003_report_a`

```yaml
effects:
  - { op: add, key: stat_trust_firm, value: 3 }
next: dialog_e020_start  # 实际由 mutex 路由至 e020*
```

### `dialog_meeting_council_player_pick`

```yaml
speaker: char_qian_demao
text_zh: |
  林外场，你也说说——这星期你怎么看？
choices:
  - id: council_speak
    label: 建言
    next: dialog_meeting_council_player_pick  # 见 DIALOG_MEETING_COUNCIL 子分支
  - id: council_silent
    label: 不言
    next: dialog_meeting_council_player_pass
```

### `dialog_m003_tasks`

```yaml
speaker: char_zhou_guanshi
text_zh: |
  外场差事：街面盯一轮，货单送清楚两趟。别砸了刚得的称呼。
effects:
  - { op: set_flag, key: flag_meeting_report_eligible, value: true }
  - { op: set_meeting_tier, value: report }
  - { op: assign_weekly_tasks, ids: [task_street_watch, task_delivery] }
next: dialog_m003_close
```

---

## 路由

| 条件 | ③ 段入口 |
|---|---|
| `route_defect` 主爽 + E020B require | `dialog_e020b_start` |
| `route_foreign` 主爽 + E020C require | `dialog_e020c_start` |
| 默认 / A 线 | `dialog_e020_start` |

E020* 的 `set_rank` 与四件套 effect 仍以各 E 文档为权威。
