# 对话 · R002 师兄报信

> 入口：`dialog_r002_start` · 事件 [`../07_事件档案/随机/R002_师兄报信.md`](../07_事件档案/随机/R002_师兄报信.md)

```
dialog_r002_start → dialog_r002_tip → END
```

```yaml
dialog_id: dialog_r002_start
event_id: R002
speaker: char_wang_pangzi
loc_key: dialog.r002.start
text_zh: |
  瑞生，过来。有件事……你自己留心就行，别说是我说的。
require:
  - { loc: loc_02 }
  - { edge: {from: char_wang_pangzi, to: char_lin_ruisheng}, tier_in: [相善, 厚交] }
  - { edge: {from: char_wang_pangzi, to: char_lin_ruisheng}, key: score, op: ">=", value: 40 }
tags: [random]
next: dialog_r002_tip

dialog_id: dialog_r002_tip
speaker: narrator
loc_key: dialog.r002.tip
text_zh: |
  王胖子压低嗓子，把商行里刚冒头的动静递给你。话不多，却顶用。
effects:
  - { op: add_range, key: stat_intel, min: 5, max: 10 }
next: null
```
