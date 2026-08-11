# 对话 · E010b 深夜可疑货物（推迟）

> 入口：`dialog_e010b_start` · 事件 [`../07_事件档案/主线/E010b_深夜可疑货物_推迟.md`](../07_事件档案/主线/E010b_深夜可疑货物_推迟.md)

```
dialog_e010b_start → dialog_e010b_choice → A/B（无离开）
```

```yaml
dialog_id: dialog_e010b_start
event_id: E010b
speaker: narrator
loc_key: dialog.e010b.start
text_zh: |
  又是深夜。同一条暗道，同一批「南洋木器」。你上次走开了——这一次，机会未必再给。
require:
  - { flag: flag_e010_delayed, value: true }
  - { key: stat_intel, op: ">=", value: 10 }
  - { clue: clue_suspicious_manifest, owned: true }
  - { loc: loc_02 }
tags: [mainline, opium_arc]
next: dialog_e010b_choice

dialog_id: dialog_e010b_choice
event_id: E010b
speaker: narrator
loc_key: dialog.e010b.choice_prompt
text_zh: |
  （不能再装看不见了。）
choices:
  - id: A
    loc_key: dialog.e010b.choice.a
    text_zh: 躲在暗处，把细节记全
    effects:
      - { op: add, key: stat_intel, value: 10 }
      - { op: add, key: stat_suspicion, value: 5 }
      - { op: unlock_clue, id: clue_light_crate }
      - { op: set_flag, key: flag_e010_delayed, value: false }
    next: dialog_e010b_outro_a
  - id: B
    loc_key: dialog.e010b.choice.b
    text_zh: 靠近偷看箱内
    check:
      require: { key: stat_intel, op: ">=", value: 15 }
      on_pass:
        effects:
          - { op: add, key: stat_intel, value: 15 }
          - { op: add, key: stat_suspicion, value: 15 }
          - { op: unlock_clue, id: clue_light_crate, quality: partial }
          - { op: set_flag, key: flag_e010_delayed, value: false }
        next: dialog_e010b_outro_b_ok
      on_fail:
        effects:
          - { op: add, key: stat_suspicion, value: 25 }
          - { op: add, key: stat_trust_firm, value: -15 }
          - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -10 }
          - { op: set_flag, key: flag_e010_delayed, value: false }
        next: dialog_e010b_outro_b_fail

dialog_id: dialog_e010b_outro_a
speaker: narrator
loc_key: dialog.e010b.outro.a
text_zh: |
  「轻箱之谜」终于落了实处。暗道、东家、轻箱——账房里若还有一本账，你就能把线接上。
next: null

dialog_id: dialog_e010b_outro_b_ok
speaker: narrator
loc_key: dialog.e010b.outro.b_ok
text_zh: |
  又是那股甜腻焦味。你退回阴影里，手指还在抖。
next: null

dialog_id: dialog_e010b_outro_b_fail
speaker: narrator
loc_key: dialog.e010b.outro.b_fail
text_zh: |
  这一回被发现，东家的警告更冷：「再让我看见你半夜转，就不用来了。」
next: null
```
