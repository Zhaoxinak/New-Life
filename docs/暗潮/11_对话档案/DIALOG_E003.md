# 对话 · E003 货单异常

> 入口：`dialog_e003_start` · 事件 [`../07_事件档案/主线/E003_货单异常.md`](../07_事件档案/主线/E003_货单异常.md)  
> 线索：[`clue_suspicious_manifest`](../08_线索档案/CLUE_可疑货单.md)

---

## 节点图

```
dialog_e003_start
  → dialog_e003_notice
  → dialog_e003_math
  → dialog_e003_choice
       ├─ A → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

### `dialog_e003_start`

```yaml
dialog_id: dialog_e003_start
event_id: E003
speaker: narrator
loc_key: dialog.e003.start
text_zh: |
  林瑞生在整理货单时，注意到一批货的记录有些奇怪。
tags: [mainline, opium_arc]
next: dialog_e003_notice
```

### `dialog_e003_notice`

```yaml
dialog_id: dialog_e003_notice
speaker: narrator
loc_key: dialog.e003.notice
text_zh: |
  货单上记着「南洋木器·二十箱」，到岸价每箱三两七。但林瑞生清楚记得，这批货的箱体尺寸比普通木箱小了一半，搬运时苦力却没有使全力——轻得很。
next: dialog_e003_math
```

### `dialog_e003_math`

```yaml
dialog_id: dialog_e003_math
speaker: narrator
loc_key: dialog.e003.math
text_zh: |
  这不对劲。二十箱「木器」，每箱三两七，总共七十四两。可这批货走的是快船直运，运费比普通货高了三倍。谁会为了七十四两的木头花二十二两运费？
next: dialog_e003_choice
```

### `dialog_e003_choice`

```yaml
dialog_id: dialog_e003_choice
event_id: E003
speaker: narrator
loc_key: dialog.e003.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e003.choice.a
    text_zh: 追上去问苦力
    effects:
      - { op: add, key: stat_intel, value: 5 }
      - { op: add, key: stat_suspicion, value: 5 }
      - { op: unlock_clue, id: clue_suspicious_manifest }
    next: dialog_e003_outro_a
  - id: B
    loc_key: dialog.e003.choice.b
    text_zh: 默默记下，不动声色
    effects:
      - { op: add, key: stat_intel, value: 3 }
      - { op: unlock_clue, id: clue_suspicious_manifest, quality: partial }
    next: dialog_e003_outro_b
  - id: C
    loc_key: dialog.e003.choice.c
    text_zh: 假装没看见
    effects:
      - { op: set_flag, key: flag_day3_ignored, value: true }
    next: dialog_e003_outro_c
```

### Outros

```yaml
dialog_id: dialog_e003_outro_a
speaker: narrator
loc_key: dialog.e003.outro.a
text_zh: |
  苦力支支吾吾说不知道，只说「东家吩咐走暗道入库」。你把这张单子，记进了心里。
next: null

dialog_id: dialog_e003_outro_b
speaker: narrator
loc_key: dialog.e003.outro.b
text_zh: |
  你没声张。纸上的数、箱子的轻，都先压着——日后对得上再说。
next: null

dialog_id: dialog_e003_outro_c
speaker: narrator
loc_key: dialog.e003.outro.c
text_zh: |
  你翻过下一张货单。有些事，假装没看见，也许更省事。
next: null
```
