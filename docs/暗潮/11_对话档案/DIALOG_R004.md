# 对话 · R004 柳如烟哭诉

> 入口：`dialog_r004_start` · 事件 [`../07_事件档案/随机/R004_柳如烟哭诉.md`](../07_事件档案/随机/R004_柳如烟哭诉.md)

```
dialog_r004_start → dialog_r004_liu → dialog_r004_choice
  ├─ A comfort → outro_a
  └─ B cold → outro_b
```

```yaml
dialog_id: dialog_r004_start
event_id: R004
speaker: narrator
loc_key: dialog.r004.start
text_zh: |
  夜里，如烟来到货栈小屋，眼圈红着，话还没出口先哽住了。
require:
  - { loc: loc_06 }
  - { slot: evening }
  - { edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, tier_in: [相善, 厚交] }
  - { meter: pursuit, op: ">=", value: 30 }
tags: [random]
next: dialog_r004_liu

dialog_id: dialog_r004_liu
speaker: char_liu_ruyan
loc_key: dialog.r004.liu
text_zh: |
  瑞生……他又来了。送东西、问东问西。我心里乱得很，你到底……怎么看我？
next: dialog_r004_choice

dialog_id: dialog_r004_choice
event_id: R004
speaker: narrator
loc_key: dialog.r004.choice_prompt
text_zh: |
  （你怎么应？）
tags: [random, choice]
choices:
  - id: A
    loc_key: dialog.r004.choice.a
    text_zh: 软声安慰，让她靠着你
    effects:
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 10 }
    next: dialog_r004_outro_a
  - id: B
    loc_key: dialog.r004.choice.b
    text_zh: 冷着脸，只说「你自己看着办」
    effects:
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: -10 }
    next: dialog_r004_outro_b

dialog_id: dialog_r004_outro_a
speaker: narrator
loc_key: dialog.r004.outro.a
text_zh: |
  她把额头抵在你肩上，哭声小了。这一晚，她更黏你一分。
next: null

dialog_id: dialog_r004_outro_b
speaker: narrator
loc_key: dialog.r004.outro.b
text_zh: |
  她愣住，随后咬着唇走了。门关上的声音很轻，却像砸在你心口。
next: null
```
