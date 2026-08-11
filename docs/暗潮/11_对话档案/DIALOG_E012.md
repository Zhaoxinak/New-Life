# 对话 · E012 利用柳如烟

> 入口：`dialog_e012_start` · 事件 [`../07_事件档案/主线/E012_利用柳如烟.md`](../07_事件档案/主线/E012_利用柳如烟.md)  
> 硬前置：E008 选隐忍（`flag_endure_preview`）且柳→林交情够深。

---

## 节点图

```
dialog_e012_start
  → dialog_e012_liu_line
  → dialog_e012_choice
       ├─ A → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

```yaml
dialog_id: dialog_e012_start
event_id: E012
speaker: narrator
loc_key: dialog.e012.start
text_zh: |
  钱子安不断给人送礼。红绸、衣料、首饰——退回去，第二天又送到厂门口。
  今夜如烟来找你，又慌又愧，袖口还攥着一块新布的边。那不是布料，是价码；收一回，往后就都要拿钱说话了。
require:
  - { edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, op: ">=", value: 40 }
  - { flag: flag_endure_preview, value: true }
tags: [mainline]
next: dialog_e012_liu_line

dialog_id: dialog_e012_liu_line
speaker: char_liu_ruyan
loc_key: dialog.e012.liu_line
text_zh: |
  瑞生，他又送了衣料来。我退回去，他的人又送来。我……我不知道怎么办。
next: dialog_e012_choice

dialog_id: dialog_e012_choice
event_id: E012
speaker: char_lin_ruisheng
loc_key: dialog.e012.choice_prompt
text_zh: |
  （沉默片刻。灯芯噼啪一声。）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e012.choice.a
    text_zh: 教她收下礼物，暗中替你打听消息
    effects:
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: -5 }
      - { op: add, key: stat_intel, value: 15 }
      - { op: set_flag, key: flag_liu_spy, value: true }
    next: dialog_e012_outro_a
  - id: B
    loc_key: dialog.e012.choice.b
    text_zh: 让她坚决拒绝，一件都不留
    effects:
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 10 }
      - { op: add, edge: {from: char_qian_zian, to: char_lin_ruisheng}, key: score, value: -10 }
      - { op: add, meter: pursuit, value: 5 }
      - { op: set_flag, key: flag_liu_channel_closed, value: true }
    next: dialog_e012_outro_b
  - id: C
    loc_key: dialog.e012.choice.c
    text_zh: 让她拖延——不收，也不撕破脸
    effects:
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 5 }
      - { op: set_flag, key: flag_liu_channel_half, value: true }
    next: dialog_e012_outro_c
```

### Outros

```yaml
dialog_id: dialog_e012_outro_a
speaker: narrator
loc_key: dialog.e012.outro.a
text_zh: |
  如烟点头时手在抖。你把自己的未婚妻推进了仇人的视线里。
  情报会来。代价也会来。
  （此后 meter.pursuit 可自然增长，并伴随点滴情报。）
next: null

dialog_id: dialog_e012_outro_b
speaker: narrator
loc_key: dialog.e012.outro.b
text_zh: |
  如烟松了口气。少爷吃了闭门羹，未必善罢甘休——送礼没买下人，他只会更恼。
  这条枕边渠道，关上了；可你也替她守住了一层最薄的体面。
next: null

dialog_id: dialog_e012_outro_c
speaker: narrator
loc_key: dialog.e012.outro.c
text_zh: |
  「再拖拖。」如烟应得很轻。渠道半开，钱子安的耐心在耗，你的时间也在耗。
next: null
```
