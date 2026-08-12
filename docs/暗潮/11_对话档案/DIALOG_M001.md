# 对话 · M001 首次旁听朝账

> 入口：`dialog_m001_start` · 事件 [`../07_事件档案/朝账/M001_首次旁听朝账.md`](../07_事件档案/朝账/M001_首次旁听朝账.md)  
> 演出：门外旁听模式（剪影 + 关键字高亮）。

---

## 节点图

```
dialog_m001_start
  → dialog_m001_zhou_order      # 周管事：门外候着
  → dialog_m001_rollcall        # ① 点名（旁听）
  → dialog_m001_report_wang     # ② 王胖子汇报 + 学徒序播报
  → dialog_m001_demao_comment   # 东家短评
  → dialog_m001_paojie_echo     # 听见「林跑街」
  → dialog_m001_manshi_hint     # ③ 满师再议
  → dialog_m001_council_zhou    # ④ 周管事建言（旁听）
  → dialog_m001_council_wang_pass # ④ 王胖子不语
  → dialog_m001_policy_wood     # ⑤ 木材定调
  → dialog_m001_tasks           # ⑥ 摊派 + effects
  → dialog_m001_close
```

---

## Nodes（摘要）

### `dialog_m001_start`

```yaml
speaker: narrator
text_zh: |
  考校刚散，前堂里已有人摆好了茶碗。周管事朝门帘外一指——今日是朝账日，你不够格入堂，只能在门外续茶、听着。
next: dialog_m001_zhou_order
```

### `dialog_m001_council_zhou`

```yaml
speaker: char_zhou_guanshi
text_zh: |
  ……后院这几日按章走。谁要图省事，最后省的是东家的脸。
tags: [meeting, council, keyword_highlight]
next: dialog_m001_council_wang_pass
```

### `dialog_m001_council_wang_pass`

```yaml
speaker: narrator
text_zh: |
  王胖子没接话。堂里顿了一下——原来建言时，也可以不说。
tags: [meeting, council]
next: dialog_m001_policy_wood
```

### `dialog_m001_report_wang`

```yaml
dialog_id: dialog_m001_report_wang
speaker: char_wang_pangzi
text_zh: |
  ……学徒里这周小陈排第一，瑞生第二。货单错两处，已改。
tags: [meeting, ladder]
next: dialog_m001_demao_comment
```

### `dialog_m001_paojie_echo`

```yaml
dialog_id: dialog_m001_paojie_echo
speaker: char_qian_demao
text_zh: |
  ……林跑街，本月街面应酬你盯紧。瑞生满师的事，名册上先搁着，跑街这位置，不是光记数字就行的。
tags: [meeting, keyword_highlight]
next: dialog_m001_manshi_hint
```

### `dialog_m001_tasks`

```yaml
speaker: char_zhou_guanshi
text_zh: |
  你——本周把货单理清楚两遍，前堂值更别躲。朝账前做不利索，堂里就没你的位子。
effects:
  - { op: init_ladder_pool, pool_id: pool_apprentice }
  - { op: set_flag, key: flag_meeting_witness, value: true }
  - { op: set_meeting_tier, value: listen }
  - { op: init_council_queue, ids: [char_zhou_guanshi, char_wang_pangzi] }
  - { op: assign_weekly_tasks, ids: [task_tidy_manifest, task_front_duty] }
next: dialog_m001_close
```

### `dialog_m001_close`

```yaml
speaker: narrator
text_zh: |
  门帘落下，堂里的声音闷成一团。你低头看手里的茶托——跑街、满师、月例，全在那一道门里分。
next: null
```
