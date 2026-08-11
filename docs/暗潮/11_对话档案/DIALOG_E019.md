# 对话 · E019 密账一用

> 入口：`dialog_e019_start` · 事件 [`../07_事件档案/主线/E019_密账一用.md`](../07_事件档案/主线/E019_密账一用.md)

```
dialog_e019_start → dialog_e019_hook → dialog_e019_choice
  ├─ A → outro_a
  ├─ B → outro_b
  └─ C → outro_c
```

```yaml
dialog_id: dialog_e019_start
event_id: E019
speaker: narrator
loc_key: dialog.e019.start
text_zh: |
  前堂为着一笔货单口径争起来。对方嗓门不小，显然没把你放在眼里。
  你袖里那点从账房摸来的数，此刻像一块烫手的铁。
tags: [mainline]
next: dialog_e019_hook

dialog_id: dialog_e019_hook
speaker: narrator
loc_key: dialog.e019.hook
text_zh: |
  ——用，还是按住？
next: dialog_e019_choice

dialog_id: dialog_e019_choice
speaker: narrator
loc_key: dialog.e019.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e019.choice.a
    text_zh: 点到为止，逼他让步
    effects:
      - { op: add, key: stat_intel, value: 3 }
      - { op: add, key: stat_trust_firm, value: 5 }
      - { op: add, key: stat_suspicion, value: 3 }
      - { op: set_flag, key: flag_e019_done, value: true }
      - { op: set_flag, key: flag_info_edge_used, value: true }
    next: dialog_e019_outro_a
  - id: B
    loc_key: dialog.e019.choice.b
    text_zh: 咬得更死
    effects:
      - { op: add, key: stat_trust_firm, value: 8 }
      - { op: add, key: stat_suspicion, value: 8 }
      - { op: add, edge: {from: char_zhou_guanshi, to: char_lin_ruisheng}, key: score, value: -5 }
      - { op: set_flag, key: flag_e019_done, value: true }
      - { op: set_flag, key: flag_info_edge_used, value: true }
    next: dialog_e019_outro_b
  - id: C
    loc_key: dialog.e019.choice.c
    text_zh: 按住不用
    effects:
      - { op: add, key: stat_intel, value: 2 }
      - { op: set_flag, key: flag_e019_done, value: true }
      - { op: set_flag, key: flag_info_edge_saved, value: true }
    next: dialog_e019_outro_c

dialog_id: dialog_e019_outro_a
speaker: narrator
loc_key: dialog.e019.outro.a
text_zh: |
  你只报了一个数、一个日子。对方脸色一变，话头矮了半截。
  围观的人看你的眼神换了——不是敬，是忌。忌就够了。
next: null

dialog_id: dialog_e019_outro_b
speaker: narrator
loc_key: dialog.e019.outro.b
text_zh: |
  你追着问了两句不该问穿的。差事是赢了，可周管事的目光像钉子。
  有些赢，会记在别人的小本上。
next: null

dialog_id: dialog_e019_outro_c
speaker: narrator
loc_key: dialog.e019.outro.c
text_zh: |
  你把铁按回袖里。今天不当众烫人——留给以后更贵的场合。
next: null
```
