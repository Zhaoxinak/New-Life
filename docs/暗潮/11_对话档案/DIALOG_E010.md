# 对话 · E010 深夜可疑货物

> 入口：`dialog_e010_start` · 事件 [`../07_事件档案/主线/E010_深夜可疑货物.md`](../07_事件档案/主线/E010_深夜可疑货物.md)  
> 线索 A/B成功 → [`clue_light_crate`](../08_线索档案/CLUE_轻箱之谜.md)  
> 选 C → Day13 重入 [`DIALOG_E010b.md`](DIALOG_E010b.md)

---

## 节点图

```
dialog_e010_start
  → dialog_e010_notice
  → dialog_e010_doubt
  → dialog_e010_choice
       ├─ A → outro_a
       ├─ B → check intel≥15 → pass/fail
       └─ C → outro_c（推迟）
```

---

## Nodes

```yaml
dialog_id: dialog_e010_start
event_id: E010
speaker: narrator
loc_key: dialog.e010.start
text_zh: |
  林瑞生因加班留到深夜，经过后院库房时，听到搬运声。几个不认识的苦力正从一辆遮了篷布的马车上卸箱子。箱子外标着「南洋木器」，和 Day 3 那批货单上的字，一模一样。
require:
  - { key: stat_intel, op: ">=", value: 10 }
  - { clue: clue_suspicious_manifest, owned: true }
  - { flag: flag_day3_ignored, value: false }
  - { loc: loc_02 }
tags: [mainline, opium_arc]
next: dialog_e010_notice

dialog_id: dialog_e010_notice
speaker: narrator
loc_key: dialog.e010.notice
text_zh: |
  箱子搬起来轻飘飘的。苦力们不走正门，钻后门暗道。更怪的是——钱德茂亲自站在暗道口，神色紧张。你从没见他半夜盯过一车木头。
next: dialog_e010_doubt

dialog_id: dialog_e010_doubt
speaker: narrator
loc_key: dialog.e010.doubt
text_zh: |
  正经木材生意，需要东家亲自守夜吗？
next: dialog_e010_choice

dialog_id: dialog_e010_choice
event_id: E010
speaker: narrator
loc_key: dialog.e010.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e010.choice.a
    text_zh: 躲在暗处观察，记下细节
    effects:
      - { op: add, key: stat_intel, value: 10 }
      - { op: add, key: stat_suspicion, value: 5 }
      - { op: unlock_clue, id: clue_light_crate }
    next: dialog_e010_outro_a
  - id: B
    loc_key: dialog.e010.choice.b
    text_zh: 靠近偷看箱内货物
    check:
      require: { key: stat_intel, op: ">=", value: 15 }
      on_pass:
        effects:
          - { op: add, key: stat_intel, value: 15 }
          - { op: add, key: stat_suspicion, value: 15 }
          - { op: unlock_clue, id: clue_light_crate, quality: partial }
        next: dialog_e010_outro_b_ok
      on_fail:
        effects:
          - { op: add, key: stat_suspicion, value: 25 }
          - { op: add, key: stat_trust_firm, value: -15 }
          - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -10 }
        next: dialog_e010_outro_b_fail
  - id: C
    loc_key: dialog.e010.choice.c
    text_zh: 离开，不打草惊蛇
    effects:
      - { op: add, key: stat_intel, value: 3 }
      - { op: set_flag, key: flag_e010_delayed, value: true }
    next: dialog_e010_outro_c
```

### Outros

```yaml
dialog_id: dialog_e010_outro_a
speaker: narrator
loc_key: dialog.e010.outro.a
text_zh: |
  深夜卸货、暗道入库、东家亲自盯场——你把这些记成「轻箱之谜」。箱子里究竟是什么，还差临门一脚。
next: null

dialog_id: dialog_e010_outro_b_ok
speaker: narrator
loc_key: dialog.e010.outro.b_ok
text_zh: |
  撬开一条缝：油纸里裹着黑色膏状物，甜腻焦味扑鼻。你没敢掀到底，心里却已经发沉——这绝不是木器。
next: null

dialog_id: dialog_e010_outro_b_fail
speaker: narrator
loc_key: dialog.e010.outro.b_fail
text_zh: |
  「不该看的别看。」钱德茂的声音不重，像钉进骨头。你退出暗处，背上全是冷汗。
next: null

dialog_id: dialog_e010_outro_c
speaker: narrator
loc_key: dialog.e010.outro.c
text_zh: |
  你转身离开。脚步很轻，心里却记下：这种车，还会再来。
next: null
```
